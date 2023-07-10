// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './interface/INFTPool.sol';
import './interface/IERC20.sol';
import './interface/IERC721.sol';
import './libraries/TransferHelper.sol';
import "hardhat/console.sol";
import './NFTAuction.sol';
import './interface/INFTToken.sol';

contract NFTPool is INFTPool {
    address token;
    uint256 public totalSupply;

    bytes4 private constant SELECTOR = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    uint256 initCount = 1000 * 10 ** 18;
    uint256 registerCount = 0;

    mapping(address => mapping (uint256 => uint256)) public nftAccount;
    mapping(address => mapping (uint256 => int)) public nftState;
    mapping(address => mapping (uint256 => uint256)) public nftRedeemAccount;
    mapping(address => mapping (uint256 => address)) public nftOwner;

    uint256 private unlocked = 1;
    address public factory; //工厂地址
    address public bank;
    address public auctionAddress;
    address nftVault;

    constructor() {
        //factory地址为合约布署者
        factory = msg.sender;
    }


    modifier lock() {
        require(unlocked == 1, "NFTPool: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }


    receive() external payable {} // to support receiving ETH by default
    fallback() external payable {}
    
    function initialize(address _token, address _bank, address _auction, address _nftVault)  external {
        require(msg.sender == factory, "NFTPool: FORBIDDEN");
        token = _token;
        bank = _bank;
        auctionAddress = _auction;
        nftVault = _nftVault;
    }

    function _safeTransfer(
        address _token,
        address to,
        uint256 value
    ) private {
        //调用token合约地址的低级transfer方法
        //solium-disable-next-line
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        //确认返回值为true并且返回的data长度为0或者解码后为true
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "NFTPool: TRANSFER_FAILED"
        );
    }

    function transferIntoNFT(address nft, uint256 tokenId) external lock override {
        require(nft != address(0), "transfer to the zero NFT address");
        uint256 nftCount = IERC20(token).balanceOf(address(this));
        uint256 transferCount = nftCount - totalSupply;
        require(transferCount > 0 , "transfer count <= 0.");
        nftAccount[nft][tokenId] += transferCount;
        totalSupply = nftCount;
        if (token == nftVault) {
            INFTToken(nftVault).updateMoneyInNFT(int256(transferCount));
        }
    }


    function registerNFT(address nft, uint256 tokenId) external override {
        nftAccount[nft][tokenId] = 0;
        if (token == nftVault) {
            if (registerCount % 1000 == 0) {
                registerCount = 0;
                initCount /= 2;
            }
            registerCount += 1;
            INFTToken(nftVault).updateMoneyInNFT(int256(registerCount));
            nftAccount[nft][tokenId] = initCount;
            INFTToken(nftVault).registerMint(initCount);
        }
    }

    function getNFTMortgageInfo(address nft, uint256 tokenId) external view override returns (uint256) {
        return nftRedeemAccount[nft][tokenId];
    }

    function getNFTAccount(address nft, uint256 tokenId) external view override returns (uint256) {
        return nftAccount[nft][tokenId];
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    function checkLiquidateNFTPrice(address nft, uint256 tokenId) external view override returns (uint256) {
        return nftAccount[nft][tokenId];
    }
    
    function checkNFTStatus(address nft, uint256 tokenId) external view override returns (int) {
        return nftState[nft][tokenId];
    }

    function mortgageNFT(address nft, uint256 tokenId, uint256 amount, address to, uint timeReturn) external lock override {
        require(msg.sender == bank, "not bank");
        require(nft != address(0), "transfer to the zero NFT address");
        require(IERC721(nft).supportsInterface(0x80ac58cd), "not ERC721");
        require(IERC721(nft).ownerOf(tokenId) == address(this), "not owner");
        require(nftAccount[nft][tokenId] >= amount, "not enough");
        require(block.timestamp < timeReturn, "time error");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Not_Enough_Token");
        IERC20(token).approve(address(this), amount);
        IERC20(token).transferFrom(address(this), to, amount);
        // TransferHelper.safeTransferFrom(token, address(this), to, amount);
        nftAccount[nft][tokenId] -= amount;
        nftRedeemAccount[nft][tokenId] = amount;
        nftOwner[nft][tokenId] = to;
        nftState[nft][tokenId] = int(timeReturn);
        totalSupply = IERC20(token).balanceOf(address(this));
        if (token == nftVault) {
            INFTToken(nftVault).updateMoneyInNFT(-int256(amount));
        }
    }

    function redeemNFT(address nft, uint256 tokenId, address to) external lock override {
        require(msg.sender == bank, "not bank");
        require(nft != address(0), "transfer to the zero NFT address");
        require(nftState[nft][tokenId] > int(block.timestamp), "time error");
        require(IERC721(nft).supportsInterface(0x80ac58cd), "not ERC721");
        require(IERC721(nft).ownerOf(tokenId) == address(this), "not nft owner");
        require(nftOwner[nft][tokenId] == to, "not old owner");
        uint256 transferIn = IERC20(token).balanceOf(address(this)) - totalSupply;
        require(transferIn >= nftRedeemAccount[nft][tokenId] , "not enough");
        IERC721(nft).approve(to, tokenId);
        IERC721(nft).safeTransferFrom(address(this), to, tokenId);
        if(transferIn > nftRedeemAccount[nft][tokenId]){
            _safeTransfer(token, to, transferIn - nftRedeemAccount[nft][tokenId]);
        }
        nftAccount[nft][tokenId] += nftRedeemAccount[nft][tokenId];
        nftRedeemAccount[nft][tokenId] = 0;
        nftState[nft][tokenId] = 0;
        nftOwner[nft][tokenId] = address(0);
        totalSupply = IERC20(token).balanceOf(address(this));
        if (token == nftVault) {
            INFTToken(nftVault).updateMoneyInNFT(int256(transferIn));
        }
    }

    function defaultAndStartAuction(address nft, uint256 tokenId) external {
        // Only continue if redemption time has passed
        require(nftState[nft][tokenId] < int(block.timestamp), "NFTPool: Not default state yet");

        NFTAuction auction = NFTAuction(auctionAddress);
        
        // Create the auction for the NFT
        IERC721(nft).approve(address(auction), tokenId);
        IERC721(nft).safeTransferFrom(address(this), address(auction), tokenId);
        // starting price should be the same as current nftaccount
        auction.createAuction(nft, tokenId, nftAccount[nft][tokenId]);
        
        // Update the state of the NFT
        nftState[nft][tokenId] = -1;  // -1 could mean that it's in auction
        nftOwner[nft][tokenId] = address(0);
    }


    function getTokenAddress() external view override returns (address) {
        return token;
    }
}