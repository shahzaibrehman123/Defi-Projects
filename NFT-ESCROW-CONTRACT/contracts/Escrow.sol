//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC721 {
    function transferFrom(address _from, address _to, uint _id) external;
}

contract Escrow {
    address public nftAddress;
    uint public nftID;
    uint public purchasePrice;
    uint public escrowAmount;
    address payable seller;
    address payable buyer;
    address payable inspector;
    address payable lender;

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }
    modifier onlyInspector() {
        require(
            msg.sender == inspector,
            "Only Inspector can call this function"
        );
        _;
    }

    mapping(address => bool) public approval;

    bool public inspectionPassed = false;

    receive() external payable {}

    constructor(
        address _nftAddress,
        uint _nftID,
        uint _purchasePrice,
        uint _escrowAmount,
        address payable _seller,
        address payable _buyer,
        address payable _inspector,
        address payable _lender
    ) {
        nftAddress = _nftAddress;
        nftID = _nftID;
        purchasePrice = _purchasePrice;
        escrowAmount = _escrowAmount;
        seller = _seller;
        buyer = _buyer;
        inspector = _inspector;
        lender = _lender;
    }

    function depositEarnest() public payable onlyBuyer {
        require(msg.value >= escrowAmount);
    }

    function cancelSale() public {
        if (inspectionPassed == false) {
            payable(buyer).transfer(address(this).balance);
        } else {
            payable(seller).transfer(address(this).balance);
        }
    }

    function updateInspectionStatus(bool _passed) public onlyInspector {
        inspectionPassed = _passed;
    }

    function approveSale() public {
        approval[msg.sender] = true;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function finalizeSale() public {
        require(inspectionPassed, "must be approved by inspector");
        require(approval[buyer], "must be approved by buyer");
        require(approval[seller], "must be approved by seller");
        require(approval[lender], "must be approved by lender");
        require(
            address(this).balance >= purchasePrice,
            "must have enough ether for sale"
        );

        (bool success, ) = payable(seller).call{value: address(this).balance}(
            ""
        );
        require(success);

        //Transfer owership of property
        IERC721(nftAddress).transferFrom(seller, buyer, nftID);
    }
}
