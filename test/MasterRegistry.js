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
        await registry.registerPool(pool.address);
        const registered = await registry.registeredPools(pool.address);
        expect(registered.owner).to.equal(owner.address);
    });

    it("Should update stakes for a pool", async function () {
        await registry.registerPool(pool.address);
        await registry.updateStakes(pool.address, 100);
        const registered = await registry.registeredPools(pool.address);
        expect(registered.totalStakes).to.equal(100);
    });

    it("Should prevent updating stakes for unregistered pools", async function () {
        await expect(
            registry.updateStakes(pool.address, 100)
        ).to.be.revertedWith("Master Registry: Pool not registered.");
    });
});