import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@nomiclabs/hardhat-solhint';
import * as dotenv from 'dotenv';

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.23',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      chainId: 31337,
    },
    goerli: {
      url: process.env.GOERLI_URL || '',
      chainId: 5,
      accounts: [process.env.PRIVATE_KEY || ''],
    },
    mumbai: {
      url: process.env.MUMBAI_RPC_URL,
      chainId: 80001,
      accounts: [process.env.PRIVATE_KEY || ''],
    },
    fuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      chainId: 43113,
      accounts: [process.env.PRIVATE_KEY || ''],
    },
    optimismGoerli: {
      url: 'https://optimism-goerli.publicnode.com',
      chainId: 420,
      accounts: [process.env.PRIVATE_KEY || ''],
    },
    arbitrumGoerli: {
      url: 'https://arbitrum-goerli.public.blastapi.io',
      chainId: 421613,
      accounts: [process.env.PRIVATE_KEY || ''],
    },
    arbitrumOne: {
      chainId: 42161,
      url: process.env.ARBITRUM_ONE_URL || '',
      accounts: [process.env.PRIVATE_KEY || ''],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || '',
      arbitrumOne: process.env.ARBISCAN_API_KEY || '',
      optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY || '',
      fuji: 'fuji',
      mumbai: process.env.POLYGONSCAN_API_KEY || 'mumbai',
    },
    customChains: [
      {
        network: 'fuji',
        chainId: 43113,
        urls: {
          apiURL: 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan',
          browserURL: 'https://avalanche.testnet.routescan.io',
        },
      },
      {
        network: 'mumbai',
        chainId: 80001,
        urls: {
          apiURL: 'https://api-testnet.polygonscan.com/api',
          browserURL: 'https://mumbai.polygonscan.com/',
        },
      },
    ],
  },
};

export default config;
