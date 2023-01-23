require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");

/** @type import('hardhat/config').HardhatUserConfig */
const PRIVATE_KEY = '0x794bf1c993a1c2843b0894b86bd85d6757f15e8c559e379b4a34873d64729793';
const AlchmeyURL = 'https://eth-goerli.g.alchemy.com/v2/mUob5BuwDVy8sahxWzBzYBsWHC3KG41r';

module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: AlchmeyURL,
      accounts: [PRIVATE_KEY]
    }
  },
  
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      goerli: "EGYZFEMI7IK1IUFUX44KH4J76ZQSZHK32F"
    }
  }
};