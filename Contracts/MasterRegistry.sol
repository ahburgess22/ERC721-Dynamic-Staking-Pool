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
    uint256 public globalStakes;
    uint256 public globalTokensStaked;

    event PoolRegistered(address indexed pool, address indexed owner, string indexed name);
    event GlobalStakesUpdated(uint256 globalStakes, address indexed pool);
    event PoolStakesUpdated(address indexed pool, uint256 stakes);

    function registerPool(address poolAddress, string memory name) external {
        require(poolAddress != address(0) && registeredPools[poolAddress].owner == address(0), "Master Registry: Invalid pool address or already registered.");
        
        registeredPools[poolAddress] = PoolData(msg.sender, name, 0, block.timestamp);
        emit PoolRegistered(poolAddress, msg.sender, name);
    }

    function updateStakes(address poolAddress, uint256 stakesDelta, bool isAdding) external {
        require(registeredPools[poolAddress].owner != address(0), "Master Registry: Pool not registered.");

        if (isAdding) {
            registeredPools[poolAddress].totalStakes += stakesDelta;
            globalStakes += uint256(stakesDelta);
        } else {
            require(registeredPools[poolAddress].totalStakes >= stakesDelta, "Master Registry: Insufficient stakes to remove.");
            registeredPools[poolAddress].totalStakes -= stakesDelta;
            require(globalStakes >= stakesDelta, "Master Registry: Insufficient global stakes to remove.");
            globalStakes -= stakesDelta;
        }

        emit PoolStakesUpdated(poolAddress, registeredPools[poolAddress].totalStakes);
        emit GlobalStakesUpdated(globalStakes, poolAddress);
    }

    function getPoolData(address poolAddress) external view returns (string memory name, uint256 totalStakes, uint256 createdAt) {
        require(registeredPools[poolAddress].owner != address(0), "Master Registry: Pool not registered.");

        return(registeredPools[poolAddress].name, registeredPools[poolAddress].totalStakes, registeredPools[poolAddress].createdAt);
    }
}