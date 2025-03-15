// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RentalMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsRented;

    address payable owner;
    uint256 listingPrice = 0.025 ether;

    struct RentalItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable owner;
        address payable renter;
        uint256 pricePerDay;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }

    mapping(uint256 => RentalItem) private idToRentalItem;

    event ItemListed(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        uint256 pricePerDay
    );

    event ItemRented(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        address renter,
        uint256 startTime,
        uint256 endTime
    );

    constructor() {
        owner = payable(msg.sender);
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 pricePerDay
    ) public payable nonReentrant {
        require(pricePerDay > 0, "Price must be greater than 0");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToRentalItem[itemId] = RentalItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            pricePerDay,
            0,
            0,
            true
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit ItemListed(itemId, nftContract, tokenId, msg.sender, pricePerDay);
    }

    function rentItem(uint256 itemId, uint256 rentalDays) public payable nonReentrant {
        RentalItem storage item = idToRentalItem[itemId];
        require(item.isActive, "Item is not active");
        require(item.renter == address(0), "Item is already rented");
        
        uint256 totalPrice = item.pricePerDay * rentalDays;
        require(msg.value == totalPrice, "Please submit the correct price");

        item.renter = payable(msg.sender);
        item.startTime = block.timestamp;
        item.endTime = block.timestamp + (rentalDays * 1 days);
        _itemsRented.increment();

        payable(item.owner).transfer(msg.value);

        emit ItemRented(
            itemId,
            item.nftContract,
            item.tokenId,
            item.owner,
            msg.sender,
            item.startTime,
            item.endTime
        );
    }

    function endRental(uint256 itemId) public nonReentrant {
        RentalItem storage item = idToRentalItem[itemId];
        require(block.timestamp >= item.endTime, "Rental period not ended yet");
        require(item.renter != address(0), "Item is not rented");

        IERC721(item.nftContract).transferFrom(address(this), item.owner, item.tokenId);
        
        item.renter = payable(address(0));
        item.startTime = 0;
        item.endTime = 0;
        item.isActive = false;
        
        _itemsRented.decrement();
    }

    function fetchRentalItems() public view returns (RentalItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsRented.current();
        uint256 currentIndex = 0;

        RentalItem[] memory items = new RentalItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToRentalItem[i + 1].renter == address(0)) {
                uint256 currentId = i + 1;
                RentalItem storage currentItem = idToRentalItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyListedItems() public view returns (RentalItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToRentalItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        RentalItem[] memory items = new RentalItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToRentalItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                RentalItem storage currentItem = idToRentalItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyRentedItems() public view returns (RentalItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToRentalItem[i + 1].renter == msg.sender) {
                itemCount += 1;
            }
        }

        RentalItem[] memory items = new RentalItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToRentalItem[i + 1].renter == msg.sender) {
                uint256 currentId = i + 1;
                RentalItem storage currentItem = idToRentalItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
} 