const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DynamicStakingPool", function () {
    let MasterRegistry, DynamicStakingPool;
    let registry, stakingPool, rewardToken, nftContract;
    let owner, user1, user2, snapshotId;
    const poolName = "Test";
    const MAX_SUPPLY = ethers.parseEther("1000000");

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

    it("Should register itself in the MasterRegistry upon deployment", async function () {
        const name = poolName
        await registry.registerPool(stakingPool.runner.address, name);
        const registered = await registry.registeredPools(stakingPool.runner.address);
        expect(registered.owner).to.equal(owner.address);
    });

    it("Should allow a user to stake a token", async function () {
        // Mint a NFT for user1
        const tx = await stakingPool.connect(user1).createToken();
        const receipt = await tx.wait();

        // Parse the logs to find the mintedToken event
        const tokenId = receipt.logs[1].args[1];
    
        // Stake the NFT
        await stakingPool.connect(user1).stake(tokenId);
    
        // Validate staking updates
        const stakes = await stakingPool.getUserStakes(user1.address);
        expect(stakes.length).to.be.greaterThan(0);
        const registered = await registry.registeredPools(stakingPool.target);
        expect(registered.totalStakes).to.equal(1);
    });
     

    it("Should calculate and distribute rewards when a user unstakes", async function () {
        // Mint a NFT for user1
        const tx = await stakingPool.connect(user1).createToken();
        const receipt = await tx.wait();

        // Parse the logs to find the mintedToken event
        const tokenId = receipt.logs[1].args[1];
    
        // Stake the NFT
        await stakingPool.connect(user1).stake(tokenId);

        // Unstake the NFT and mint RTKs after establishing stakingContract
        await rewardToken.setStakingContract(stakingPool.target);
        await stakingPool.connect(user1).unstake(tokenId);

        // Validate rewards
        const rewardBalance = await stakingPool.getRewardBalance(user1.address);
        expect(rewardBalance).to.be.gt(0);

        const registered = await registry.registeredPools(stakingPool.target);
        expect(registered.totalStakes).to.equal(0);
    });

    it("Should prevent unstaking a token not owned by the caller", async function () {
        // Mint a NFT for user1
        const tx = await stakingPool.connect(user1).createToken();
        const receipt = await tx.wait();

        // Parse the logs to find the mintedToken event
        const tokenId = receipt.logs[1].args[1];

        // Stake the NFT with a user
        await stakingPool.connect(user1).stake(tokenId);

        // Try to unstake with a different user
        await expect(stakingPool.connect(user2).unstake(tokenId)).to.be.revertedWith("DST: Token not staked by user.");
    });

    it("Should handle multiple users staking and unstaking", async function () {
        // Mint NFTs for user1 and user2
        const tx = await stakingPool.connect(user1).createToken();
        const receipt1 = await tx.wait();
        const tx2 = await stakingPool.connect(user2).createToken();
        const receipt2 = await tx2.wait();

        // Parse the logs to find the tokenIDs
        const tokenId1 = receipt1.logs[1].args[1];
        const tokenId2 = receipt2.logs[1].args[1];

        // Stake NFTs
        await stakingPool.connect(user1).stake(tokenId1);
        await stakingPool.connect(user2).stake(tokenId2);

        // Validate total stakes
        const registered = await registry.registeredPools(stakingPool.target);
        expect(registered.totalStakes).to.equal(2);

        // Users unstake NFTs and mint RTKs after establishing stakingContract
        await rewardToken.setStakingContract(stakingPool.target);
        await stakingPool.connect(user1).unstake(tokenId1);
        await stakingPool.connect(user2).unstake(tokenId2);

        const registeredAfterUnstake = await registry.registeredPools(stakingPool.target);
        expect(registeredAfterUnstake.totalStakes).to.equal(0);
    });
});
