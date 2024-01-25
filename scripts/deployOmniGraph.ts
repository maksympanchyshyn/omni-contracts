import hre, { ethers } from 'hardhat';

type LzChain = {
  name: string;
  chainId: number;
  lzChainId: number;
  lzEndpoint: string;
};

const LzChains: LzChain[] = [
  {
    name: 'Goerli',
    chainId: 5,
    lzChainId: 10121,
    lzEndpoint: '0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23',
  },
  {
    name: 'Fuji',
    chainId: 43113,
    lzChainId: 10106,
    lzEndpoint: '0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706',
  },
  {
    name: 'Mumbai',
    chainId: 80001,
    lzChainId: 10109,
    lzEndpoint: '0xf69186dfBa60DdB133E91E9A4B5673624293d8F8',
  },
  {
    name: 'Arbitrum-Goerli',
    chainId: 421613,
    lzChainId: 10143,
    lzEndpoint: '0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab',
  },
  {
    name: 'Optimism-Goerli',
    chainId: 420,
    lzChainId: 10132,
    lzEndpoint: '0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1',
  },
];

const getDeployArgsForChain = (network: string): [number, string, number, number] => {
  switch (network) {
    case 'fuji':
      // fuji
      return [150000, '0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706', 1, 99];
    case 'mumbai':
      // mumbai
      return [150000, '0xf69186dfBa60DdB133E91E9A4B5673624293d8F8', 100, 199];
    default:
      throw new Error(`Invalid chainId. Probably unsupported network passed`);
  }
};

async function main() {
  const network = hre.network;

  if (!network.config.chainId) {
    console.log(`Invalid network, missing chainId`);
    return;
  }

  const deployArgs = getDeployArgsForChain(hre.network.name);

  const omniGraph = await ethers.deployContract('OmniGraph', deployArgs);
  await omniGraph.waitForDeployment();

  console.log(`OmniGraph deployed on ${network.name} to ${omniGraph.target}`);
  console.log(
    `To verify contract run: npx hardhat verify --network ${network.name} ${
      omniGraph.target
    } ${deployArgs.join(' ')}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
