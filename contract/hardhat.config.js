/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");


const ALCHEMY_API_KEY = "aIoa2uPd0Oquq-6_4xzUtdGT6SfCw0nd";

// 从 Metamask 导出你的私钥，打开Metamask，并进入帐户详细信息>导出私钥
// 千万注意，永远不要把真实的Ether转到测试帐户
const ROPSTEN_PRIVATE_KEY = "Your private key";
const localKey = "eba19bb8a20107b39b88667cd849a437bd3cf11cfe6c09857e17259e819675dd"

module.exports = {
  // solidity: "0.8.18",

  solidity: {
    compilers: [    //可指定多个sol版本
        {version: "0.8.18"},
        {version: "0.5.16"}
    ]
  },

  networks: {
    /*Ganache: {
      url: "http://127.0.0.1:7545",
      chainId: 5777,
    }, */
    // goerli: {
    //   url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
    //   accounts: [`${ROPSTEN_PRIVATE_KEY}`]
    // }
    localhost: {
      url: "http://127.0.0.1:7545",
      accounts: [`${localKey}`]
    }
  }
};
