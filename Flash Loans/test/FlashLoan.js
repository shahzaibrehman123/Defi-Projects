const { expect } = require("chai");
const { ethers } = require("hardhat");

const tokens = (n) => {
  return ethers.utils.parseEther(n.toString(), "ether");
};

const ether = tokens;

describe("FlashLoan", async () => {
  let token, flashLoan, flashLoanReceiver;
  let deployer;

  beforeEach(async () => {
    //Setup Accounts
    accounts = await ethers.getSigners();
    deployer = accounts[0];

    //Load Accounts
    const FLashLoan = await ethers.getContractFactory("FlashLoan");
    const FlashLoanReceiver = await ethers.getContractFactory(
      "FlashLoanReceiver"
    );
    const Token = await ethers.getContractFactory("Token");

    //Deploy Token
    token = await Token.deploy("Loan Token", "LT", "1000000");

    //Deploy Flash Loan Pool
    flashLoan = await FLashLoan.deploy(token.address);

    //Approval for Token Transfer
    let transaction = await token
      .connect(deployer)
      .approve(flashLoan.address, tokens(1000000));
    await transaction.wait();

    transaction = await flashLoan
      .connect(deployer)
      .depositTokens(tokens(1000000));
    await transaction.wait();

    //Deploy Flash Loan Receiver

    flashLoanReceiver = await FlashLoanReceiver.deploy(flashLoan.address);
  });

  describe("Deployment", async () => {
    it("1 million token transfered from token contract to flashloan contract", async () => {
      expect(await token.balanceOf(flashLoan.address)).to.equal(
        tokens(1000000)
      );
    });
  });

  describe("Borrowing Funds", async () => {
    it("borrows funds from the pool", async () => {
      let amount = tokens(100);
      let transaction = await flashLoanReceiver
        .connect(deployer)
        .executeFlashLoan(amount);
      await expect(transaction)
        .to.emit(flashLoanReceiver, "LoanReceived")
        .withArgs(token.address, amount);
    });
  });
});
