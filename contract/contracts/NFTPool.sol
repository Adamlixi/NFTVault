// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './interface/INFTPool.sol';
import './interface/IERC20.sol';
import './interface/IERC721.sol';
import './libraries/TransferHelper.sol';
import "hardhat/console.sol";

contract NFTPool is INFTPool {
    address token;
    uint256 public totalSupply;

    bytes4 private constant SELECTOR = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );

    mapping(address => mapping (uint256 => uint256)) public nftAccout;
    mapping(address => mapping (uint256 => int)) public nftState;
    mapping(address => mapping (uint256 => uint256)) public nftRedeemAccount;
    mapping(address => mapping (uint256 => address)) public nftOwner;
    mapping(address => uint256[]) public nftTokens;
    uint256 private unlocked = 1;
    address public factory; //工厂地址
    address public bank;


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
    
    function initialize(address _token, address _bank)  external {
        require(msg.sender == factory, "NFTPool: FORBIDDEN");
        token = _token;
        bank = _bank;
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
        nftAccout[nft][tokenId] += transferCount;
        totalSupply = nftCount;
    }


    function registerNFT(address nft, uint256 tokenId) external override {
        nftAccout[nft][tokenId] = 0;
        nftTokens[nft].push(tokenId);
    }

    function getNFTTokens(address nft) external view returns (uint256[] memory) {
        return nftTokens[nft];
    }

    function getNFTMortgageInfo(address nft, uint256 tokenId) external view override returns (uint256) {
        return nftRedeemAccount[nft][tokenId];
    }

    function getNFTAccount(address nft, uint256 tokenId) external view override returns (uint256) {
        return nftAccout[nft][tokenId];
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    function checkLiquidateNFTPrice(address nft, uint256 tokenId) external view override returns (uint256) {
        return nftAccout[nft][tokenId];
    }
    
    function checkNFTStatus(address nft, uint256 tokenId) external view override returns (int) {
        return nftState[nft][tokenId];
    }

    function mortgageNFT(address nft, uint256 tokenId, uint256 amount, address to, uint timeReturn) external lock override {
        require(msg.sender == bank, "not bank");
        require(nft != address(0), "transfer to the zero NFT address");
        require(IERC721(nft).supportsInterface(0x80ac58cd), "not ERC721");
        require(IERC721(nft).ownerOf(tokenId) == address(this), "not owner");
        require(nftAccout[nft][tokenId] >= amount, "not enough");
        require(block.timestamp < timeReturn, "time error");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Not_Enough_Token");
        IERC20(token).approve(address(this), amount);
        IERC20(token).transferFrom(address(this), to, amount);
        // TransferHelper.safeTransferFrom(token, address(this), to, amount);
        nftAccout[nft][tokenId] -= amount;
        nftRedeemAccount[nft][tokenId] = amount;
        nftOwner[nft][tokenId] = to;
        nftState[nft][tokenId] = int(timeReturn);
        totalSupply = IERC20(token).balanceOf(address(this));
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
        nftAccout[nft][tokenId] += nftRedeemAccount[nft][tokenId];
        nftRedeemAccount[nft][tokenId] = 0;
        nftState[nft][tokenId] = 0;
        nftOwner[nft][tokenId] = address(0);
        totalSupply = IERC20(token).balanceOf(address(this));
    }

    function getTokenAddress() external view override returns (address) {
        return token;
    }
}