const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RentalMarketplace", function () {
  let RentalMarketplace;
  let rentalMarketplace;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    RentalMarketplace = await ethers.getContractFactory("RentalMarketplace");
    rentalMarketplace = await RentalMarketplace.deploy();
    await rentalMarketplace.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await rentalMarketplace.owner()).to.equal(owner.address);
    });

    it("Should set the correct listing price", async function () {
      const listingPrice = await rentalMarketplace.getListingPrice();
      expect(listingPrice).to.equal(ethers.utils.parseEther("0.025"));
    });
  });

  describe("Marketplace operations", function () {
    it("Should fail if listing price is not correct", async function () {
      await expect(
        rentalMarketplace.listItem(
          ethers.constants.AddressZero,
          1,
          ethers.utils.parseEther("1"),
          { value: ethers.utils.parseEther("0.01") }
        )
      ).to.be.revertedWith("Price must be equal to listing price");
    });

    it("Should fail if rental price is 0", async function () {
      await expect(
        rentalMarketplace.listItem(ethers.constants.AddressZero, 1, 0, {
          value: ethers.utils.parseEther("0.025"),
        })
      ).to.be.revertedWith("Price must be greater than 0");
    });
  });
});
