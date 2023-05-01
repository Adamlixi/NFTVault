async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    // const Token = await ethers.getContractFactory("Token");
    // const token = await Token.deploy();

    // NFTVault Test Coin
    const Tokens = await ethers.getContractFactory("NFTVaultTest");
    const token = await Tokens.deploy();

    const WETH = await ethers.getContractFactory("WETH9");
    const weth = await WETH.deploy();
  
    console.log("NFTVaultTest Token address:", token.address);
    console.log("WETH address:", weth.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });