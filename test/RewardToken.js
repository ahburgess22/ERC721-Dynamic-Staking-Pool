const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RewardToken", function () {
  let MasterRegistry, DynamicStakingPool;
    let registry, stakingPool, rewardToken, nftContract;
    let owner, user1, user2, snapshotId;
    const poolName = "Test";
    const MAX_SUPPLY = ethers.parseEther("1000000000000");

    beforeEach(async function () {
        snapshotId = await ethers.provider.send("evm_snapshot", []);

        // Get the contract factories and signers
        [owner, user1, user2] = await ethers.getSigners();
    
        MasterRegistry = await ethers.getContractFactory("MasterRegistry");
        const RewardToken = await ethers.getContractFactory("RewardToken");
        const NFTCreator = await ethers.getContractFactory("NFT");
        DynamicStakingPool = await ethers.getContractFactory("DynamicStakingPool");
    
        // Deploy MasterRegistry
        registry = await MasterRegistry.deploy();
    
        // Deploy RewardToken
        rewardToken = await RewardToken.deploy(MAX_SUPPLY);
    
        // Deploy NFTCreator
        nftContract = await NFTCreator.deploy();

        // Deploy DynamicStakingPool with references to all dependencies
        stakingPool = await DynamicStakingPool.deploy(
            nftContract.target,
            rewardToken.target,
            registry.target,
            poolName
        );
    });
    
    afterEach(async () => {
        await ethers.provider.send("evm_revert", [snapshotId]);
    });

    it("Should have correct name, symbol, and cap", async function () {
        expect(await rewardToken.name()).to.equal("Reward Token");
        expect(await rewardToken.symbol()).to.equal("RTK");
        expect(await rewardToken.cap()).to.equal(ethers.parseUnits("1000000000000")); // 1e12
    });

    it("Should have the same RewardToken owner and DSP owner", async function () {
        dspOwner = await owner.address;
        rtkOwner = await rewardToken.owner();
        expect(dspOwner).to.be.equal(rtkOwner);
    })

    it("Should allow only the owner to set authorized staking address", async function () {
        await expect(
        rewardToken.connect(user1).setAuthorizedStaker(stakingPool.runner.address)).to.be.reverted;
    });

    it("Should only allow minting from authorized staker", async function () {
        // Mint RTK to owner from authorized user
        await rewardToken.connect(owner).setAuthorizedStaker(user1);
        await rewardToken.connect(user1).mint(owner.address, 100);
        expect(await rewardToken.balanceOf(owner.address)).to.be.equal(100);

        // Try minting RTK from unauthorized account
        expect(rewardToken.connect(user2).mint(owner.address, 100)).to.be.revertedWith("RTK: Unauthorized");
    });

    it("Should not allow minting above the cap", async function () {
        // Attempt to mint up to the cap
        await rewardToken.mint(user1.address, ethers.parseUnits("999999999999"));
        await expect(
        rewardToken.mint(user1.address, ethers.parseUnits("2"))
        ).to.be.revertedWith("RTK: ERC20 cap exceeded.");
    });

    it("Should update balances correctly on transfer", async function () {
        await rewardToken.mint(user1.address, ethers.parseUnits("1000"));

        // Transfer tokens
        await rewardToken.connect(user1).transfer(user2.address, ethers.parseUnits("500"));
        expect(await rewardToken.balanceOf(user1.address)).to.equal(ethers.parseUnits("500"));
        expect(await rewardToken.balanceOf(user2.address)).to.equal(ethers.parseUnits("500"));
    });

    it("Should handle ERC20Capped updates properly", async function () {
        await rewardToken.mint(user1.address, ethers.parseUnits("100"));

        // Update balances through _update function (internal logic check)
        await rewardToken.testUpdate(user1.address, user2.address, ethers.parseUnits("100"));
        expect(await rewardToken.balanceOf(user1.address)).to.equal(ethers.parseUnits("0"));
        expect(await rewardToken.balanceOf(user2.address)).to.equal(ethers.parseUnits("100"));
    });
});