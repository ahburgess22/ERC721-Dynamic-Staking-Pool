//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RegistryHelpers.sol";

contract MasterRegistry {
    struct PoolData {
        address owner;
        string name;
        uint256 totalStakes;
        uint256 createdAt;
        uint256 rareNFTs;
        uint256 legendaryNFTs;
        uint256 stakingPower;
    }

    mapping(address => PoolData) public registeredPools;
    address[] public poolAddresses; // Tracking address to use later when selecting winning validator
    uint256 public globalStakes;
    uint256 public globalPools;
    uint public rewardRate;
    uint public baseReward = BaseReward.updateBaseReward();
    uint public globalStakingPower = 0;

    // Events
    event PoolRegistered(uint256 globalPools, address indexed pool, address indexed owner, string name);
    event GlobalStakesUpdated(uint256 globalStakes, address indexed pool);
    event PoolStakesUpdated(string poolName, uint256 stakes);
    event RewardRateUpdated(uint256 rewardRate, uint256 globalPools, uint256 globalStakes);
    event PoolStakingPowerUpdated(string poolName, uint256 poolStakingPower, uint256 globalStakingPower);
    event WinnerSelected(string winningPool, uint256 poolStakingPower, uint256 globalStakingPower);

    function registerPool(address poolAddress, string memory name) external {
        require(poolAddress != address(0) && registeredPools[poolAddress].owner == address(0), "Master Registry: Invalid pool address or already registered.");
        
        registeredPools[poolAddress] = PoolData(msg.sender, name, 0, block.timestamp, 0, 0, 0);
        globalPools++;
        updateRewardRate(baseReward, globalPools, globalStakes);
        poolAddresses.push(poolAddress);
        emit PoolRegistered(globalPools, poolAddress, msg.sender, name);
    }

    function updateStakes(address poolAddress, uint256 stakesDelta, bool isAdding, bool isRare, bool isLegendary) external {
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

        // Checking if NFT is rare or legendary for staking calculations later
        if (isRare) {
            registeredPools[poolAddress].rareNFTs++;
        } else if (isLegendary) {
            registeredPools[poolAddress].legendaryNFTs++;
        }

        uint256 newStakingPower = PoolWeight.updatePoolStakingPower(registeredPools[poolAddress].rareNFTs, registeredPools[poolAddress].legendaryNFTs, registeredPools[poolAddress].totalStakes);
        globalStakingPower += newStakingPower - registeredPools[poolAddress].stakingPower; // Add only new token's value to the global staking power
        registeredPools[poolAddress].stakingPower = newStakingPower;
        emit PoolStakingPowerUpdated(registeredPools[poolAddress].name, registeredPools[poolAddress].stakingPower, globalStakingPower);
       
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

    function getWinner() public returns(string memory) {
        // Check to be sure at least 2 pools have each staked, otherwise prevent abuse of the market
        require(globalPools > 1 && registeredPools[poolAddresses[0]].stakingPower < globalStakingPower, "Master Registry: No competing pools or stakes.");

        uint total = 0;
        uint winningNum = Validator._getWinner(globalStakingPower); // Random number generated between 0 and globalStakingPower
        
        for(uint i = 0; i < poolAddresses.length; i++) { // Keeps adding to total until poolStakingPowers accumulate to winningNum
            total += registeredPools[poolAddresses[i]].stakingPower; // Larger poolStakingPower has better chance of reaching winningNum
            if (total > winningNum) {
                emit WinnerSelected(registeredPools[poolAddresses[i]].name, registeredPools[poolAddresses[i]].stakingPower, globalStakingPower);
                baseReward = BaseReward.updateBaseReward(); // New base reward simulates reward for validating the upcoming block
                updateRewardRate(baseReward, globalPools, globalStakes); // Calculate new reward rate based on new baseReward
                return registeredPools[poolAddresses[i]].name;
            }
        }

        revert("Master Registry: Error selecting winner.");
    }


}