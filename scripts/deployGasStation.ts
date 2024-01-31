import hre, { ethers } from 'hardhat';
import { Network } from 'hardhat/types';

import { LZ_CHAINS } from '../constants';

const getLzEndpoint = (network: Network) => {
  const lzChain = LZ_CHAINS.find((i) => i.chainId === network.config.chainId);
  if (!lzChain) {
    throw new Error(`Missing LZ Endpoint for chainId ${network.config.chainId} (${network.name})`);
  }
  return lzChain.lzEndpoint;
};

async function main() {
  const network = hre.network;
  const lzEndpoint = getLzEndpoint(network);
  const gasStation = await ethers.deployContract('GasStation', [lzEndpoint]);
  await gasStation.waitForDeployment();

  console.log(`GasStation deployed on ${network.name} to ${gasStation.target}`);
  console.log(
    `To verify contract run: npx hardhat verify --network ${network.name} ${gasStation.target} ${lzEndpoint}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
