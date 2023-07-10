// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./NFTRouter.sol";
import "./interface/IWETH.sol";

contract Exchange {
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

    NFTRouter public nftRouter;
    IWETH public weth;
    mapping(uint256 => Order) public orderBook;

    uint256 public orderCount = 0;

    event OrderCreated(uint256 orderId);
    event OrderRemoved(uint256 orderId);
    event OrderPublished(uint256 orderId);
    event OrderUpdated(uint256 orderId, Status status);
    event OrderFilled(uint256 orderId, address buyer);
    event OrderCanceled(uint256 indexed orderId);

    constructor(NFTRouter _nftRouter, IWETH _weth) {
        nftRouter = _nftRouter;
        weth = _weth;
    }

    function getOrder(uint256 orderId) public view returns (Order memory) {
        return orderBook[orderId];
    }

    function getNFTRouter() public view returns (NFTRouter) {
        return nftRouter;
    }

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

        nftRouter.registerNFT(nftContract, tokenId, tokenContract);

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

    function updateOrderStatus(uint256 orderId, Status status)
        public
        onlyAuthorized(orderId)
    {
        orderBook[orderId].status = status;
        emit OrderUpdated(orderId, status);
    }

    modifier onlyAuthorized(uint256 orderId) {
        require(orderBook[orderId].maker == msg.sender, "Not authorized");
        _;
    }

    function fillOrder(uint256 orderId) public {
        Order memory order = getOrder(orderId);
        require(
            order.status == Status.Open,
            "Order is not open"
        );

        uint256 sellerAmount = (order.price * 97) / 100;
        uint256 nftAccountAmount = order.price - sellerAmount;

        // First, we need to transfer the specified amount of the payment token
        // from the buyer (msg.sender) to the NFTRouter.
        // Assume that the buyer has already approved the transfer.
        IERC20(order.tokenContract).transferFrom(
            msg.sender,
            address(this),
            nftAccountAmount
        );

        IERC20(order.tokenContract).approve(
            address(nftRouter),
            nftAccountAmount
        );

        IERC20(order.tokenContract).transferFrom(
            msg.sender,
            order.maker,
            sellerAmount
        );
        // Then, we call transferIntoNFT on the NFTRouter.
        nftRouter.transferIntoNFT(
            order.nftContract,
            order.tokenId,
            nftAccountAmount
        );
        // After that, the NFT needs to be transferred from the seller (maker) to the buyer.
        // Assume that the seller has already approved the transfer.
        IERC721(order.nftContract).transferFrom(
            order.maker,
            msg.sender,
            order.tokenId
        );

        // Update the order status.
        order.status = Status.Filled;

        emit OrderFilled(orderId, msg.sender);
    }



    function cancelOrder(uint256 orderId) public {
        Order memory order = getOrder(orderId);

        require(
            order.status == Status.Open,
            "Order is not open"
        );

        order.status = Status.Cancelled;

        emit OrderCanceled(orderId);
    }

    function fillOrderWithEther(uint256 orderId) public payable {
        Order memory order = getOrder(orderId);
        require(
            order.status == Status.Open,
            "Order is not open"
        );
        require(msg.value == order.price, "Incorrect ETH value sent");

        uint256 sellerAmount = (order.price * 97) / 100;
        uint256 nftAccountAmount = order.price - sellerAmount;

        // Wrap the incoming ETH to WETH for the part that will be used in transferIntoNFT
        weth.deposit{value: nftAccountAmount}();

        // Perform the trade
        (bool sent, ) = order.maker.call{value: sellerAmount}(""); // Transfer the Ether to the seller
        require(sent, "Failed to send Ether");

        weth.approve(address(nftRouter), nftAccountAmount);
        nftRouter.transferIntoNFT(
            order.nftContract,
            order.tokenId,
            nftAccountAmount
        );
        IERC721(order.nftContract).transferFrom(
            order.maker,
            msg.sender,
            order.tokenId
        );

        // Unwrap the remaining WETH back to ETH, which should be zero as it's all been used in transferIntoNFT
        // weth.withdraw(nftAccountAmount);
        order.status = Status.Filled;
        emit OrderFilled(orderId, msg.sender);
    }

    function getFillOrderResults(
        uint256 orderId
    )
        public
        view
        returns (
            address maker,
            address nftContract,
            address tokenContract,
            uint256 tokenId,
            uint256 price,
            uint256 expiration,
            Status status
        )
    {
        Order memory order = getOrder(orderId);

        require(
            order.status == Status.Filled,
            "Order has not been filled"
        );

        return (
            order.maker,
            order.nftContract,
            order.tokenContract,
            order.tokenId,
            order.price,
            order.expiration,
            order.status
        );
    }
}
