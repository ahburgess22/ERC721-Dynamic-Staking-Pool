//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MasterRegistry {
    struct PoolData {
        address owner;
        string name;
        uint256 totalStakes;
        uint256 createdAt;
    }

    mapping(address => PoolData) public registeredPools;

    event PoolRegistered(address indexed pool, address indexed owner, string indexed name);
    event StakesUpdated(address indexed pool, uint totalStakes);

    function registerPool(address poolAddress, string memory name) external {
        require(poolAddress != address(0) && registeredPools[poolAddress].owner == address(0), "Master Registry: Invalid pool address or already registered.");
        
        registeredPools[poolAddress] = PoolData(msg.sender, name, 0, block.timestamp);
        emit PoolRegistered(poolAddress, msg.sender, name);
    }

    function updateStakes(address poolAddress, uint256 stakes) external {
        require(registeredPools[poolAddress].owner != address(0), "Master Registry: Pool not registered.");
        registeredPools[poolAddress].totalStakes = stakes;
        emit StakesUpdated(poolAddress, stakes);
    }

    function getPoolData(address poolAddress) external view returns (string memory name, uint256 totalStakes, uint256 createdAt) {
        require(registeredPools[poolAddress].owner != address(0), "Master Registry: Pool not registered.");

        return(registeredPools[poolAddress].name, registeredPools[poolAddress].totalStakes, registeredPools[poolAddress].createdAt);
    }
}