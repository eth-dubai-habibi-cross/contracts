// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract RewardManager is OwnerIsCreator, ERC2771Context, FunctionsClient {
  using FunctionsRequest for FunctionsRequest.Request;

  bytes32 public donId; // DON ID for the Functions DON to which the requests are sent

  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  event Response(bytes32 indexed requestId, bytes response, bytes err);

  error NotEnoughBalance(uint256 currentBalance, uint256 required);
  error NotWhitelisted(address user);
  error InsufficientRewards(uint256 available, uint256 required);

  event RewardSent(
    bytes32 indexed messageId,
    uint64 destinationChainSelector,
    address destinationContractAddress,
    address receiver,
    uint256 amount,
    address feeToken,
    uint256 fees
  );
  event RewardAdded(address indexed user, uint256 amount);
  event UserWhitelisted(address indexed user);
  event UserRemovedFromWhitelist(address indexed user);
  event RewardDirectlySent(address indexed user, uint256 amount);

  IRouterClient private s_router;
  LinkTokenInterface private s_linkToken;
  IERC20 public usdc;

  // Mapping for reward balances
  mapping(address => uint256) public rewardBalances;
  // Whitelist mapping
  mapping(address => bool) private whitelisted;

  constructor(
    address _functionsRouter,
    address _router,
    address _link,
    address _usdc,
    address _trustedForwarder,
    bytes32 _donId
  ) OwnerIsCreator() ERC2771Context(_trustedForwarder) FunctionsClient(_functionsRouter) {
    s_router = IRouterClient(_router);
    s_linkToken = LinkTokenInterface(_link);
    usdc = IERC20(_usdc);
    donId = _donId;
  }

  function setDonId(bytes32 newDonId) external onlyOwner {
    donId = newDonId;
  }

  function sendRequest(
    string calldata source,
    FunctionsRequest.Location secretsLocation,
    bytes calldata encryptedSecretsReference,
    string[] calldata args,
    bytes[] calldata bytesArgs,
    uint64 subscriptionId,
    uint32 callbackGasLimit
  ) external onlyOwner returns (bytes32 requestId) {
    FunctionsRequest.Request memory req;
    req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, source);
    req.secretsLocation = secretsLocation;
    req.encryptedSecretsReference = encryptedSecretsReference;
    if (args.length > 0) {
      req.setArgs(args);
    }
    if (bytesArgs.length > 0) {
      req.setBytesArgs(bytesArgs);
    }
    s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, callbackGasLimit, donId);
    return s_lastRequestId;
  }

  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
    s_lastResponse = response;
    s_lastError = err;
    emit Response(requestId, s_lastResponse, s_lastError);

    // Process the response to update rewards
    if (response.length > 0) {
      // response --> (address, amount)
      (address user, uint256 amount) = abi.decode(response, (address, uint256));
      whitelisted[user] = true;
      rewardBalances[user] = amount;
    }
  }

  // Add or update rewards for a user
  function addReward(address user, uint256 amount) public onlyOwner {
    require(whitelisted[user], "User not whitelisted");
    rewardBalances[user] += amount;
    emit RewardAdded(user, amount);
  }

  // Whitelist a user
  function whitelistUser(address user) public onlyOwner {
    whitelisted[user] = true;
    emit UserWhitelisted(user);
  }

  // Remove a user from whitelist
  function removeUserFromWhitelist(address user) public onlyOwner {
    whitelisted[user] = false;
    emit UserRemovedFromWhitelist(user);
  }

  // A new function that allows users to directly claim their rewards on the current chain
  function claimRewardSource() public {
    address user = _msgSender();
    require(whitelisted[user], "Not whitelisted");
    uint256 amount = rewardBalances[user];
    require(amount > 0, "No rewards available");

    rewardBalances[user] = 0; // Deduct first to prevent reentrancy

    require(usdc.transfer(user, amount), "USDC transfer failed");

    emit RewardDirectlySent(user, amount);
  }

  // Function for gamers to claim their rewards
  function claimRewards(uint64 destinationChainSelector, address destinationContractAddress) public {
    require(whitelisted[_msgSender()], "Not whitelisted");
    uint256 amount = rewardBalances[_msgSender()];
    require(amount > 0, "No rewards available");

    // Deduct the reward balance before sending to prevent re-entrancy attacks
    rewardBalances[_msgSender()] = 0;

    bytes32 messageId = sendReward(destinationChainSelector, destinationContractAddress, _msgSender(), amount);

    emit RewardSent(
      messageId,
      destinationChainSelector,
      destinationContractAddress,
      _msgSender(),
      amount,
      address(s_linkToken),
      0
    ); // Fees are handled within sendReward
  }

  // Function to send USDC rewards across chains
  function sendReward(
    uint64 destinationChainSelector,
    address receiver,
    address withdrawAddress,
    uint256 amount
  ) internal returns (bytes32 messageId) {
    // Encode the receiver address and amount for the message
    bytes memory data = abi.encode(withdrawAddress, amount);

    Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
      receiver: abi.encode(receiver),
      data: data,
      tokenAmounts: new Client.EVMTokenAmount[](0),
      extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
      feeToken: address(s_linkToken)
    });

    // The message includes USDC transfer, fees are calculated accordingly
    uint256 fees = s_router.getFee(destinationChainSelector, evm2AnyMessage);

    if (fees > s_linkToken.balanceOf(address(this)))
      revert NotEnoughBalance({currentBalance: s_linkToken.balanceOf(address(this)), required: fees});

    // Approve LINK token for fees
    s_linkToken.approve(address(s_router), fees);

    // Send the cross-chain message
    messageId = s_router.ccipSend(destinationChainSelector, evm2AnyMessage);

    return messageId;
  }

  // Function to check the reward balance of a caller
  function getRewardBalance() public view returns (uint256) {
    require(whitelisted[_msgSender()], "Not whitelisted");
    return rewardBalances[_msgSender()];
  }

  // Function to check if a caller is whitelisted
  function isWhitelisted() public view returns (bool) {
    return whitelisted[_msgSender()];
  }
}
