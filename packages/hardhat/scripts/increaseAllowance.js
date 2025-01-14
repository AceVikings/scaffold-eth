// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const TokenFactory = await hre.ethers.getContractFactory("Token");
  const Token = await TokenFactory.attach(
    "0x2dfb6d18A247dee62BF91857aFB25098F689bf4D"
  );
  await Token.increaseAllowance(
    "0x0ac2deCEDe3c5E1E937802b144bc4449b7065Cd7",
    hre.ethers.utils.parseEther("1000")
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
