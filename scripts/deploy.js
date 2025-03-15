const hre = require("hardhat");

async function main() {
  const RentalMarketplace = await hre.ethers.getContractFactory("RentalMarketplace");
  const rentalMarketplace = await RentalMarketplace.deploy();

  await rentalMarketplace.deployed();

  console.log("RentalMarketplace deployed to:", rentalMarketplace.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 