const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RewardToken", function () {
    let RewardToken, rewardToken;
  let owner, stakingContract, addr1, addr2;

  beforeEach(async function () {
    // Deploy the RewardToken contract
    RewardToken = await ethers.getContractFactory("RewardToken");
    [owner, stakingContract, addr1, addr2] = await ethers.getSigners();

    rewardToken = await RewardToken.deploy(ethers.parseUnits("1000000000000")); // 1e12 cap
    });

    it("Should have correct name, symbol, and cap", async function () {
        expect(await rewardToken.name()).to.equal("Reward Token");
        expect(await rewardToken.symbol()).to.equal("RTK");
        expect(await rewardToken.cap()).to.equal(ethers.parseUnits("1000000000000")); // 1e12
    });

    it("Should allow only the owner to set the staking contract", async function () {
        await rewardToken.connect(owner).setStakingContract(stakingContract.address);
        contractAddress = await rewardToken.getStakingContract();
        expect(contractAddress).to.equal(stakingContract.address);

        await expect(
        rewardToken.connect(addr1).setStakingContract(addr1.address)).to.be.reverted;
    });

    it("Should allow minting only from the staking contract", async function () {
        await rewardToken.connect(owner).setStakingContract(stakingContract.address);

        // Mint from the staking contract
        await rewardToken.connect(stakingContract).mint(addr1.address, ethers.parseUnits("1000"));
        expect(await rewardToken.balanceOf(addr1.address)).to.equal(ethers.parseUnits("1000"));

        // Mint from an unauthorized address
        await expect(
        rewardToken.connect(addr1).mint(addr2.address, ethers.parseUnits("1000"))
        ).to.be.revertedWith("RTK: Caller is not the staking contract.");
    });

    it("Should not allow minting above the cap", async function () {
        await rewardToken.connect(owner).setStakingContract(stakingContract.address);

        // Attempt to mint up to the cap
        await rewardToken.connect(stakingContract).mint(addr1.address, ethers.parseUnits("999999999999"));
        await expect(
        rewardToken.connect(stakingContract).mint(addr1.address, ethers.parseUnits("2"))
        ).to.be.revertedWith("RTK: ERC20 cap exceeded.");
    });

    it("Should update balances correctly on transfer", async function () {
        await rewardToken.connect(owner).setStakingContract(stakingContract.address);
        await rewardToken.connect(stakingContract).mint(addr1.address, ethers.parseUnits("1000"));

        // Transfer tokens
        await rewardToken.connect(addr1).transfer(addr2.address, ethers.parseUnits("500"));
        expect(await rewardToken.balanceOf(addr1.address)).to.equal(ethers.parseUnits("500"));
        expect(await rewardToken.balanceOf(addr2.address)).to.equal(ethers.parseUnits("500"));
    });

    it("Should handle ERC20Capped updates properly", async function () {
        await rewardToken.connect(owner).setStakingContract(stakingContract.address);
        await rewardToken.connect(stakingContract).mint(addr1.address, ethers.parseUnits("100"));

        // Update balances through _update function (internal logic check)
        await rewardToken.connect(stakingContract).testUpdate(addr1.address, addr2.address, ethers.parseUnits("100"));
        expect(await rewardToken.balanceOf(addr1.address)).to.equal(ethers.parseUnits("0"));
        expect(await rewardToken.balanceOf(addr2.address)).to.equal(ethers.parseUnits("100"));
    });
});