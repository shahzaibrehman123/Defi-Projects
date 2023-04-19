// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "hardhat/console.sol";
import "./FlashLoan.sol";
import "./Token.sol";

contract FlashLoanReceiver {
    FlashLoan private pool;
    address private owner;

    event LoanReceived(address token, uint256 amount);

    constructor(address _poolAddress) {
        pool = FlashLoan(_poolAddress);
        owner = msg.sender;
    }

    function receiveTokens(address _tokenAddress, uint _amount) external {
        //only pool can call this function
        require(msg.sender == address(pool), " Sender must be pool ");

        //Require funds received
        require(
            Token(_tokenAddress).balanceOf(address(this)) == _amount,
            "failed to get loan"
        );
        //Emit Event
        emit LoanReceived(_tokenAddress, _amount);

        //Add Logic to manipulate with Loan

        //Return funds to pool
        require(
            Token(_tokenAddress).transfer(msg.sender, _amount),
            "Transfer of Token Failed"
        );
    }

    function executeFlashLoan(uint _amount) external {
        require(msg.sender == owner, "only Owner");
        pool.flashloan(_amount);
    }
}
