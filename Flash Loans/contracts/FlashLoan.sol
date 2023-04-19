// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;
import "./Token.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IReceiver {
    function receiveTokens(address tokenAddress, uint amount) external;
}

contract FlashLoan is ReentrancyGuard {
    using SafeMath for uint256;
    Token public token;
    uint public poolBalance;

    constructor(address _tokenAddress) {
        token = Token(_tokenAddress);
    }

    function depositTokens(uint _amount) external nonReentrant {
        require(_amount > 0, "amount should not be equal to zero");
        token.transferFrom(msg.sender, address(this), _amount);
        poolBalance = poolBalance.add(_amount);
    }

    function flashloan(uint _burrowAmount) external nonReentrant {
        require(_burrowAmount > 0, "Must borrow at least 1 token");
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= _burrowAmount, "Not enough tokens in pool");

        // Ensured by the protocol via that `depositTokens` function
        assert(poolBalance == balanceBefore);

        // Send tokens to Receiver
        token.transfer(msg.sender, _burrowAmount);

        //Use loan, get paid back
        IReceiver(msg.sender).receiveTokens(address(token), _burrowAmount);

        //Ensure loan paid back
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore,"Flash Loan hasn't been paid back" );
    }
}
