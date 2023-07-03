// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SaveMoneyNFT.sol";

contract NFTVaultTest is ERC20, Ownable {
    uint256 interestRate = 100;
    uint256 accumulateInterestRate = 100;
    int moneyInNFT = 0;
    address admin;
    address poolAddress;
    address nftBank;
    uint256 tokenId = 0;
    mapping (uint256 => uint256) public savingInterestRate;
    mapping (uint256 => uint256) public userSavingCount;


    constructor() ERC20("NFTVaultToken", "NVC") {
        _mint(msg.sender, 20000000 * 10 ** decimals());
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only owner can call this function");
        _;
    }

    modifier onlyPool() {
        require(msg.sender == poolAddress, "Only owner can call this function");
        _;
    }

    function init(address _poolAddress, address _nftBank) public onlyAdmin {
        poolAddress = _poolAddress;
        nftBank = _nftBank;
    }

    function calculateInterestRate() public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (moneyInNFT <= 0) {
            return 0;
        }
        return totalSupply * 100 / uint256(moneyInNFT);
    }

    function updateMoneyInNFT(int tokenCounts) public onlyPool {
        moneyInNFT += tokenCounts;
    }

    function updateAccumulateInterestRate() private {
        accumulateInterestRate = accumulateInterestRate * (100 + calculateInterestRate()) / 100;
    }

    function saveMoney(uint256 moneyCount) external {
        transferFrom(msg.sender, address(this), moneyCount);
        MyToken(nftBank).safeMint(msg.sender);
        userSavingCount[tokenId] = moneyCount;
        savingInterestRate[tokenId] = accumulateInterestRate;
        tokenId += 1;
        updateAccumulateInterestRate();
    }

    function registerMint(uint256 count) external onlyPool {
        _mint(msg.sender, count);
    }

    function withDrawMoney(uint256 _tokenId, uint256 moneyCount) external {
        require(ERC721(nftBank).ownerOf(_tokenId) == msg.sender, "Not owner.");
        require(userSavingCount[_tokenId] >= moneyCount, "Not enough.");
        userSavingCount[_tokenId] = userSavingCount[_tokenId] - moneyCount;
        uint256 rateOld;
        if (savingInterestRate[tokenId] == 0) {
            rateOld = accumulateInterestRate;
        } else {
            rateOld = savingInterestRate[tokenId];
        }
        uint256 moneyWithdraw = (accumulateInterestRate/ rateOld) * moneyCount / 100;
        uint256 moneyMint = moneyWithdraw - moneyCount;
        _mint(msg.sender, moneyMint);
        transferFrom(address(this), msg.sender, moneyCount);
        updateAccumulateInterestRate();
    }

    receive() external payable {} // to support receiving ETH by default
    fallback() external payable {}
}