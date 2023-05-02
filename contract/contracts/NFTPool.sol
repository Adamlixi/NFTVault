// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './interface/INFTPool.sol';
import './interface/IERC20.sol';

contract NFTPool is INFTPool {
    address token;
    uint256 public totalSupply;

    bytes4 private constant SELECTOR = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );

    mapping(address => mapping (uint256 => uint256)) public nftAccout;
    mapping(address => mapping (uint256 => int112)) public nftState;
    mapping(address => mapping (uint256 => uint256)) public nftRedeemAccount;
    mapping(address => mapping (uint256 => address)) public nftOwner;
    uint256 private unlocked = 1;
    address public factory; //工厂地址
    address public bank;


    constructor() public {
        //factory地址为合约布署者
        factory = msg.sender;
    }


    modifier lock() {
        require(unlocked == 1, "NFTPool: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }



    function initialize(address _token, address _bank)  external {
        require(msg.sender == factory, "NFTPool: FORBIDDEN");
        token = _token;
        bank = _bank;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        //调用token合约地址的低级transfer方法
        //solium-disable-next-line
        (bool success, bytes memory data) = token.call(
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
        require(transferCount > 0 , "transfer count < 0.");
        nftAccout[nft][tokenId] += transferCount;
        totalSupply = nftCount;
    }


    function registerNFT(address nft, uint256 tokenId) external override {
        nftAccout[nft][tokenId] = 0;
    }

    function GetNFTMortgageInfo(address nft, uint256 tokenId) external view override returns (uint256) {
        return nftRedeemAccount[nft][tokenId];
    }

    function CheckLiquidateNFTPrice(address nft, uint256 tokenId) external view override returns (uint256) {
        return nftAccout[nft][tokenId];
    }
    
    function CheckNFTStatus(address nft, uint256 tokenId) external view override returns (int112) {
        return nftState[nft][tokenId];
    }

    function mortgageNFT(address nft, uint256 tokenId, uint256 amount, address to, uint256 timeReturn) external lock override {
        require(msg.sender == bank, "not bank");
        require(nft != address(0), "transfer to the zero NFT address");
        require(IERC721(nft).supportsInterface(0x80ac58cd), "not ERC721");
        require(IERC721(nft).ownerOf(tokenId) == address(this), "not owner");
        require(nftAccout[nft][tokenId] >= amount, "not enough");
        require(block.timestamp < timeReturn, "time error");
        _safeTransfer(token, to, amount);
        nftAccout[nft][tokenId] -= amount;
        nftRedeemAccount[nft][tokenId] = amount;
        nftOwner[nft][tokenId] = to;
        nftState[nft][tokenId] = int112(timeReturn);
        totalSupply = IERC20(token).balanceOf(address(this));
    }

    function redeemNFT(address nft, uint256 tokenId, address to) external lock override {
        require(msg.sender == bank, "not bank");
        require(nft != address(0), "transfer to the zero NFT address");
        require(nftState[nft][tokenId] > block.timestamp, "time error");
        require(IERC721(nft).supportsInterface(0x80ac58cd), "not ERC721");
        require(IERC721(nft).ownerOf(tokenId) == address(this), "not nft owner");
        require(nftOwner[nft][tokenId] == to, "not old owner")
        uint256 transferIn = totalSupply - IERC20(token).balanceOf(address(this));
        require(transferIn > nftRedeemAccount[nft][tokenId] , "not enough");
        IERC721(nft).safeTransferFrom(address(this), to, tokenId);
        if(transferIn > nftRedeemAccount[nft][tokenId]){
            _safeTransfer(token, to, transferIn - nftRedeemAccount[nft][tokenId]);
        }
        nftRedeemAccount[nft][tokenId] = 0;
        totalSupply = IERC20(token).balanceOf(address(this));
        nftState[nft][tokenId] = 0;
    }

    function GetTokenAddress() external view override returns (address) {
        return token;
    }
}