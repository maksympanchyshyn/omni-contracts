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
        runs: 1000,
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
    polygonMumbai: {
      url: process.env.MUMBAI_RPC_URL,
      chainId: 80001,
      accounts: [process.env.PRIVATE_KEY || ''],
    },
    avalancheFujiTestnet: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      chainId: 43113,
      accounts: [process.env.PRIVATE_KEY || ''],
    },
    optimisticGoerli: {
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
      url: process.env.ARBITRUM_ONE_URL || 'https://arbitrum.llamarpc.com',
      accounts: [process.env.PRIVATE_KEY || ''],
    },
    optimisticEthereum: {
      chainId: 10,
      url: process.env.OPTIMISM_URL || 'https://mainnet.optimism.io',
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
      avalancheFujiTestnet: 'fuji',
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || 'mumbai',
    },
  },
};

export default config;
