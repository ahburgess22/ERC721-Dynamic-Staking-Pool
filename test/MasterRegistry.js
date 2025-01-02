const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MasterRegistry", function () {
    let MasterRegistry, registry, owner, pool;

    beforeEach(async function () {
        // Get the contract factory and signers
        [owner, pool] = await ethers.getSigners();
        MasterRegistry = await ethers.getContractFactory("MasterRegistry");

        // Deploy the contract
        registry = await MasterRegistry.deploy();
        expect(registry.runner.address).to.not.be.undefined;
    });

    it("Should deploy successfully", async function () {
        expect(registry.runner.address).to.not.be.undefined;
    });

    it("Should register a new pool", async function () {
        await registry.registerPool(pool.address, "Test");
        const registered = await registry.registeredPools(pool.address);
        expect(registered.owner).to.equal(owner.address);
    });

    it("Should update stakes for a pool", async function () {
        await registry.registerPool(pool.address, "Test");
        await registry.updateStakes(pool.address, 100, true);
        const registered1 = await registry.registeredPools(pool.address);
        expect(registered1.totalStakes).to.equal(100);
        await registry.updateStakes(pool.address, 100, false);
        const registered2 = await registry.registeredPools(pool.address);
        expect(registered2.totalStakes).to.equal(0);
    });

    it("Should prevent updating stakes for unregistered pools", async function () {
        await expect(
            registry.updateStakes(pool.address, 100, true)
        ).to.be.revertedWith("Master Registry: Pool not registered.");
    });

    it("Should register and retrieve pool data", async function () {
        // Register a pool
        await registry.registerPool(pool.address, "Test");

        // Retrieve pool data
        const poolData = await registry.getPoolData(pool.address);
        expect(poolData.name).to.equal("Test");
        expect(poolData.totalStakes).to.equal(0);
    });
});