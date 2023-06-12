// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./OrderManagement.sol";

contract Exchange {

    OrderManagement public orderMgr;

    constructor(OrderManagement _orderMgr) {
        orderMgr = _orderMgr;
    }

 //   event OrderFilled(
 //       TradeDirection direction,
 //       address maker,
 //       address taker,
 //       uint256 nonce,
 //       IERC20 erc20Token,
 //       uint256 erc20TokenAmount,
 //       IERC721 erc721Token,
 //       uint256 erc721TokenId,
 //       address matcher
 //   );
 //   event OrderCanceled(uint256 nonce, address maker);
    event OrderFilled(uint256 orderId, address buyer);
    event OrderCanceled(uint256 indexed orderId);

    function fillOrder(uint256 orderId) public {
        OrderManagement.Order memory order =  orderMgr.getOrder(orderId);
        require(order.status == OrderManagement.Status.Open, "Order is not open");

        // First, we need to transfer the specified amount of the payment token
        // from the buyer (msg.sender) to the NFTRouter.
        // Assume that the buyer has already approved the transfer.
        IERC20(order.tokenContract).transferFrom(
            msg.sender,
            address(orderMgr.getNFTRouter()),
            order.price
        );

        // Then, we call transferIntoNFT on the NFTRouter.
        //nftRouter.transferIntoNFT(order.nftContract, order.tokenId, order.price);
/*  */
        // After that, the NFT needs to be transferred from the seller (maker) to the buyer.
        // Assume that the seller has already approved the transfer.
        IERC721(order.nftContract).transferFrom(
            order.maker,
            msg.sender,
            order.tokenId
        );

        // Update the order status.
        order.status = OrderManagement.Status.Filled;

        emit OrderFilled(orderId, msg.sender);
    }

    function cancelOrder(uint256 orderId) public {
        OrderManagement.Order memory order = orderMgr.getOrder(orderId);

        require(order.status == OrderManagement.Status.Open, "Order is not open");

        order.status = OrderManagement.Status.Cancelled;

        emit OrderCanceled(orderId);
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
            OrderManagement.Status status
        )
    {
        OrderManagement.Order memory order = orderMgr.getOrder(orderId);

        require(order.status == OrderManagement.Status.Filled, "Order has not been filled");

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
