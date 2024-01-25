import hre, { ethers } from 'hardhat';

import { LZ_CHAINS } from '../constants';

const getLzEndpointByChain = (chainName: string) => {
  const lzChain = LZ_CHAINS.find((i) => i.name === chainName);
  if (!lzChain) {
    throw new Error(`Network ${chainName} missing LayerZero settings`);
  }
  return lzChain.lzEndpoint;
};

async function main() {
  const network = hre.network;
  const lzEndpoint = getLzEndpointByChain(network.name);
  const gasStation = await ethers.deployContract('GasStation', [lzEndpoint]);
  await gasStation.waitForDeployment();

  console.log(`OmniGraph deployed on ${network.name} to ${gasStation.target}`);
  console.log(
    `To verify contract run: npx hardhat verify --network ${network.name} ${gasStation.target} ${lzEndpoint}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
