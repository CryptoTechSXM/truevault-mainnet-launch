require('dotenv').config();
async function main() {
  const [d] = await ethers.getSigners();
  const SAFE = '0xfabC9A20B14f1b24Ba405553FB680691E0Ec3eC8';
  const TVLT = await ethers.deployContract('TrueVaultToken', [d.address]);
  await TVLT.waitForDeployment(); console.log('TVLT →', await TVLT.getAddress());
  const Vault = await ethers.deployContract('TrueVaultUSDT', [SAFE, d.address]);
  await Vault.waitForDeployment(); console.log('Vault →', await Vault.getAddress());
  const T = await ethers.deployContract('TrueVaultTimelock', [172800, [SAFE], [SAFE], d.address]);
  await T.waitForDeployment(); console.log('Timelock →', await T.getAddress());
  await TVLT.transferOwnership(await T.getAddress());
  await Vault.transferOwnership(await T.getAddress());
  console.log('\nALL LIVE ON BSC!');
}
main();
