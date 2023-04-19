const { expect } = require("chai");
const { ethers } = require("hardhat");

const token = (n) => {
  return ethers.utils.parseEther(n.toString(), "ether");
};

const ether = token;

describe("RealEstate", () => {
  let realEstate, escrow, deployer, seller;
  let nftID = 1;
  let purchasePrice = ether(100);
  let escrowAmount = ether(20);

  beforeEach(async () => {
    //accounts
    accounts = await ethers.getSigners();
    deployer = accounts[0];
    seller = deployer;
    buyer = accounts[1];
    inspector = accounts[2];
    lender = accounts[3];

    //Load contracts
    const RealEstate = await ethers.getContractFactory("RealEstate");
    const Escrow = await ethers.getContractFactory("Escrow");

    //deploy
    realEstate = await RealEstate.deploy();

    escrow = await Escrow.deploy(
      realEstate.address,
      nftID,
      purchasePrice,
      escrowAmount,
      seller.address,
      buyer.address,
      inspector.address,
      lender.address
    );

    //seller Approves NFT
    transaction = await realEstate
      .connect(seller)
      .approve(escrow.address, nftID);
    await transaction.wait();
  });

  describe("Deployment", async () => {
    it("sends an NFT to the seller / deployer", async () => {
      expect(await realEstate.ownerOf(nftID)).to.equal(seller.address);
    });
  });

  describe("selling real estate", async () => {
    let balance, transaction;
    it("executes a successful transaction", async () => {
      //expects seller to be the owner of nft
      expect(await realEstate.ownerOf(nftID)).to.equal(seller.address);

      balance = await escrow.getBalance();
      console.log("escrow Balance:", ethers.utils.formatEther(balance));

      //Buyer Deposits earnest
      transaction = await escrow
        .connect(buyer)
        .depositEarnest({ value: escrowAmount });

      //Check Balance
      balance = await escrow.getBalance();
      console.log("escrow Balance:", ethers.utils.formatEther(balance));

      //Inspector updates status
      transaction = await escrow
        .connect(inspector)
        .updateInspectionStatus(true);
      await transaction.wait();
      console.log("Inspector update status");

      //Approved by Buyer
      transaction = await escrow.connect(buyer).approveSale();

      //Approved by seller
      transaction = await escrow.connect(seller).approveSale();

      transaction = await lender.sendTransaction({to : escrow.address, value: ether(80)})

      //Approved by lender
      transaction = await escrow.connect(lender).approveSale();

      //Finalize Sale
      transaction = await escrow.connect(buyer).finalizeSale();
      await transaction.wait();
      console.log("Buyer finalizes sale");

      //expects buyer to be the owner after the of sale of nft
      expect(await realEstate.ownerOf(nftID)).to.equal(buyer.address);

      balance = await ethers.provider.getBalance(seller.address)
      expect(balance).to.be.above(ether(10099))
      console.log("Seller Balance:", ethers.utils.formatEther(balance))
    });
  });
});
