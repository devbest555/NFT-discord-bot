// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./SafeMath.sol";
import "hardhat/console.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _items;
    Counters.Counter private _soldItems;

    address payable owner;
    address payable feeVaultAddress;
    uint256 public feePercent = 200; // 2%

    // interface to marketplace item
    struct MarketplaceItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        address payable feeVaultAddress;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketplaceItem) private idToMarketplaceItem;

    // declare a event for when a item is created on marketplace
    event MarketplaceItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        address feeVaultAddress,
        uint256 price,
        bool sold
    );

    // donate event on marketplace
    event Donate(
        address donator,
        address feeVaultAddress,
        uint256 amount
    );

    constructor(address payable _feeVaultAddress) {
        owner = payable(msg.sender);
        feeVaultAddress = _feeVaultAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // setup new fee address, onlyOwner can do
    function setFeeVaultAddress(address payable _newVaultAddress) public onlyOwner {
        require(_newVaultAddress != address(0), "Bad Address");
        feeVaultAddress = _newVaultAddress;
    }

    // setup new fee percent, onlyOwner can do
    function setFeePercent(uint256 _newFeePercent) public onlyOwner {
        require(_newFeePercent > 0, "Bad fee percent");
        require(_newFeePercent < 2000, "fee less than 20%");
        feePercent = _newFeePercent;
    }

    // returns the listing price of the contract
    function getFeePercent() public view returns (uint256) {
        return feePercent;
    }

    // setup new fee percent, onlyOwner can do
    function getFeeAmount(uint256 _price) private view returns(uint256) {
        require(_price > 0, "Price must be at least 1 wei");
        return _price.mul(feePercent).div(10000);
    }

    // places an item for sale on the marketplace
    function createMarketplaceItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(msg.value >= getFeeAmount(price), "Price must be equal to listing price");

        _items.increment();
        uint256 itemId = _items.current();

         idToMarketplaceItem[itemId] = MarketplaceItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            payable(feeVaultAddress),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketplaceItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            feeVaultAddress,
            price,
            false
        );
    }


    // creates the sale of a marketplace item
    // transfers ownership of the item, as well as funds between parties
    function createMarketplaceSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {

        uint256 price = idToMarketplaceItem[itemId].price;
        uint256 tokenId = idToMarketplaceItem[itemId].tokenId;
        require(
            msg.value >= price,
            "Please submit the asking price in order to complete the purchase"
        );

        // transfer fee
        if(feeVaultAddress != address(0)) {
            uint256 fee = getFeeAmount(price);
            payable(feeVaultAddress).transfer(fee);
            price = price.sub(fee);
        }

        idToMarketplaceItem[itemId].seller.transfer(price);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketplaceItem[itemId].owner = payable(msg.sender);
        idToMarketplaceItem[itemId].sold = true;

        _soldItems.increment();

    }

    // creates the donate of a marketplace
    function donate()
        public
        payable
        nonReentrant
    {
        require(msg.value > 0, "Bad donate amount");

        payable(feeVaultAddress).transfer(msg.value);

        emit Donate(msg.sender, feeVaultAddress, msg.value);
    }

    // returns all unsold marketplace items
    function fetchMarketplaceItems()
        public
        view
        returns (MarketplaceItem[] memory)
    {
        uint256 itemCount = _items.current();
        uint256 unsoldItemCount = _items.current() - _soldItems.current();
        uint256 currentIndex = 0;

        MarketplaceItem[] memory items = new MarketplaceItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketplaceItem[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                MarketplaceItem storage currentItem = idToMarketplaceItem[
                    currentId
                ];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

         return items;
    }

     // returns only items that a user has purchased
    function fetchMyNFTs() public view returns (MarketplaceItem[] memory) {
        uint256 totalItemCount = _items.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketplaceItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketplaceItem[] memory items = new MarketplaceItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketplaceItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketplaceItem storage currentItem = idToMarketplaceItem[
                    currentId
                ];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

     // returns only items a user has created
    function fetchItemsCreated()
        public
        view
        returns (MarketplaceItem[] memory)
    {
        uint256 totalItemCount = _items.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketplaceItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

         MarketplaceItem[] memory items = new MarketplaceItem[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketplaceItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketplaceItem storage currentItem = idToMarketplaceItem[
                    currentId
                ];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }
}