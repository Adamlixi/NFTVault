// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./NFTRouter.sol";

contract OrderManagement {
    enum Status {
        Open,
        Filled,
        Cancelled
    }
    struct Order {
        address maker;
        address nftContract;
        address tokenContract;
        uint256 tokenId;
        uint256 price;
        uint256 expiration;
        bool published;
        Status status;
    }

    mapping(uint256 => Order) public orderBook;
    uint256 public orderCount = 0;
    NFTRouter public nftRouter;

    constructor(NFTRouter _nftRouter) {
        nftRouter = _nftRouter;
    }

    event OrderCreated(uint256 orderId);
    event OrderRemoved(uint256 orderId);
    event OrderPublished(uint256 orderId);
    event OrderUpdated(uint256 orderId, Status status);

    function getOrder(uint256 orderId) public view returns(Order memory) {
        return orderBook[orderId]; // return 
    }

    function getNFTRouter() public view returns(NFTRouter) {
        return nftRouter; // return 
    }

    /* 
    create an order and emit the 'OrderCreated' event
    sample usage: const signature = await web3.eth.sign(hash, maker);
    const receit = await orderManagement.createOrder(tokenId, price, expiration, signature);
    */
    function createOrder(
        address nftContract,
        address tokenContract,
        uint256 tokenId,
        uint256 price,
        uint256 expiration,
        bytes memory signature
    ) public {
        bytes32 message = keccak256(
            abi.encodePacked(
                nftContract,
                tokenContract,
                tokenId,
                price,
                expiration
            )
        );
        bytes32 ethSignedMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        address recoveredAddress = ECDSA.recover(ethSignedMessage, signature);
        require(recoveredAddress == msg.sender, "Invalid signature");

        // Register NFT to the router contract
        //nftRouter.registerNFT(nftContract, tokenId, tokenContract);
        (bool success,) = address(nftRouter).delegatecall(
            abi.encodeWithSignature("registerNFT(address)", nftContract, tokenId, tokenContract)
        );
        require(success, "Failed delegatecall");

        Order memory newOrder = Order(
            msg.sender,
            nftContract,
            tokenContract,
            tokenId,
            price,
            expiration,
            false,
            Status.Open
        );
        orderBook[orderCount] = newOrder;

        emit OrderCreated(orderCount);
        orderCount++;
    }

    function removeOrder(uint256 orderId) public onlyAuthorized(orderId) {
        delete orderBook[orderId];
        emit OrderRemoved(orderId);
    }

    function publishOrder(uint256 orderId) public onlyAuthorized(orderId) {
        require(!orderBook[orderId].published, "Order already published");
        orderBook[orderId].published = true;
        emit OrderPublished(orderId);
    }

    function updateOrderStatus(
        uint256 orderId,
        Status status
    ) public onlyAuthorized(orderId) {
        orderBook[orderId].status = status;
        emit OrderUpdated(orderId, status);
    }

    modifier onlyAuthorized(uint256 orderId) {
        require(orderBook[orderId].maker == msg.sender, "Not authorized");
        _;
    }
}
