//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MasterRegistry {
    struct PoolData {
        address owner;
        uint256 totalStakes;
    }

    mapping(address => PoolData) public registeredPools;

    event PoolRegistered(address indexed pool, address indexed owner);
    event StakesUpdated(address indexed pool, uint totalStakes);

    function registerPool(address poolAddress) external {
        require(poolAddress != address(0) && registeredPools[poolAddress].owner == address(0), "Master Registry: Invalid pool address or already registed.");
        registeredPools[poolAddress] = PoolData(msg.sender, 0);
        emit PoolRegistered(poolAddress, msg.sender);
    }

    function updateStakes(address poolAddress, uint256 stakes) external {
        require(registeredPools[poolAddress].owner != address(0), "Master Registry: Pool not registered.");
        registeredPools[poolAddress].totalStakes = stakes;
        emit StakesUpdated(poolAddress, stakes);
    }
}