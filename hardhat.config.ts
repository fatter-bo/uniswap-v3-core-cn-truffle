import 'hardhat-typechain'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'

export default {
  networks: {
    hardhat: {
      allowUnlimitedContractSize: false,
    },
    local: {
        url: `http://127.0.0.1:7545`,
    },
    //ropsten: {
      //url: `https://eth-ropsten.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      //accounts: [`0x${ROPSTEN_PRIVATE_KEY}`]
    //},
  },
  solidity: {
    version: '0.7.6',
    settings: {
      optimizer: {
        enabled: true,
        runs: 800,
      },
      metadata: {
        // do not include the metadata hash, since this is machine dependent
        // and we want all generated code to be deterministic
        // https://docs.soliditylang.org/en/v0.7.6/metadata.html
        bytecodeHash: 'none',
      },
    },
  },
}
