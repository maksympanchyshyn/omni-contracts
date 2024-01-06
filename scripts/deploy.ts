import { ethers } from 'hardhat';

async function main() {
  const OmniGraph = await ethers.getContractFactory('OmniGraph');
  const omniGraph = await OmniGraph.deploy();

  await omniGraph.waitForDeployment();

  console.log(`OmniGraph deployed to ${omniGraph.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
