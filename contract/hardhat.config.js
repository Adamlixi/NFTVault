/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");


const ALCHEMY_API_KEY = "aIoa2uPd0Oquq-6_4xzUtdGT6SfCw0nd";

// 从 Metamask 导出你的私钥，打开Metamask，并进入帐户详细信息>导出私钥
// 千万注意，永远不要把真实的Ether转到测试帐户
const ROPSTEN_PRIVATE_KEY = "Your private key";

module.exports = {
  solidity: "0.8.18",
  networks: {
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${ROPSTEN_PRIVATE_KEY}`]
    }
  }
};
