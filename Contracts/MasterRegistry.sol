//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RegistryHelpers.sol";

contract MasterRegistry {
    struct PoolData {
        address owner;
        string name;
        uint256 totalStakes;
        uint256 createdAt;
    }

    mapping(address => PoolData) public registeredPools;
    uint256 public globalStakes;
    uint256 public globalPools;
    uint public rewardRate;
    uint public baseReward = BaseReward.updateBaseReward();

    // Events
    event PoolRegistered(uint256 globalPools, address indexed pool, address indexed owner, string indexed name);
    event GlobalStakesUpdated(uint256 globalStakes, address indexed pool);
    event PoolStakesUpdated(string indexed poolName, uint256 stakes);
    event RewardRateUpdated(uint256 rewardRate, uint256 globalPools, uint256 globalStakes);

    function registerPool(address poolAddress, string memory name) external {
        require(poolAddress != address(0) && registeredPools[poolAddress].owner == address(0), "Master Registry: Invalid pool address or already registered.");
        
        registeredPools[poolAddress] = PoolData(msg.sender, name, 0, block.timestamp);
        globalPools++;
        updateRewardRate(baseReward, globalPools, globalStakes);
        emit PoolRegistered(globalPools, poolAddress, msg.sender, name);
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

        updateRewardRate(baseReward, globalPools, globalStakes);
        emit PoolStakesUpdated(registeredPools[poolAddress].name, registeredPools[poolAddress].totalStakes);
        emit GlobalStakesUpdated(globalStakes, poolAddress);
    }

    function getPoolData(address poolAddress) external view returns (string memory name, uint256 totalStakes, uint256 createdAt) {
        require(registeredPools[poolAddress].owner != address(0), "Master Registry: Pool not registered.");

        return(registeredPools[poolAddress].name, registeredPools[poolAddress].totalStakes, registeredPools[poolAddress].createdAt);
    }

    function updateRewardRate(uint256 _baseReward, uint256 _globalPools, uint256 _globalStakes) public {
        rewardRate = RewardRate.updateRewardRate(_baseReward, _globalPools, _globalStakes);
        emit RewardRateUpdated(rewardRate, globalPools, globalStakes);
    }

    function getBaseReward() public view returns(uint256) {
        return baseReward;
    }
}