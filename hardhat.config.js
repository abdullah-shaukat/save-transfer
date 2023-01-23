require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");

/** @type import('hardhat/config').HardhatUserConfig */
const PRIVATE_KEY = '0x57c4bd30f5cf9d537a3ba29348af5e4e9d6389672aae27bf30d40fefcee7b1bd';
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