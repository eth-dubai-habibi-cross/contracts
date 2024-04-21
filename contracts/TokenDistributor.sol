// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenDistributor {
    address public admin;
    IERC20 public token;

    constructor(address _token) {
        admin = msg.sender; 
        token = IERC20(_token); 
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function distributeToken(address recipient, uint256 amount) external onlyAdmin {
        require(token.transfer(recipient, amount), "Token transfer failed");
    }
}
