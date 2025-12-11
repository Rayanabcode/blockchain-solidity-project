const { ethers } = require("hardhat");

async function main() {
  console.log("Starting deployment...");

  // Get the contract factory for the CollateralizedLoan contract
  const CollateralizedLoan = await ethers.getContractFactory("CollateralizedLoan");

  // Deploy the contract
  const contract = await CollateralizedLoan.deploy();

  // Wait for the deployment to be mined (ethers v6)
  await contract.waitForDeployment();

  // Get the deployed contract address (ethers v6)
  const address = await contract.getAddress();

  console.log(`CollateralizedLoan deployed successfully at address: ${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("An error occurred during deployment:", error);
    process.exit(1);
  });