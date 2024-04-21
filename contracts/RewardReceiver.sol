// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardReceiver is CCIPReceiver {
    // Address of the token contract for rewards (e.g., USDC)
    IERC20 public rewardToken;

    event RewardClaimed(address indexed recipient, uint256 amount);

    constructor(address _router, address _rewardToken) CCIPReceiver(_router) {
        rewardToken = IERC20(_rewardToken);
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        // Decode the message to get the recipient address and the amount
        (address recipient, uint256 amount) = abi.decode(any2EvmMessage.data, (address, uint256));

        // Transfer the rewards to the recipient
        require(rewardToken.transfer(recipient, amount), "Reward transfer failed");

        emit RewardClaimed(recipient, amount);
    }
}
