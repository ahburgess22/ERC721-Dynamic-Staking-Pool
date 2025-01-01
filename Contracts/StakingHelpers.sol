// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./CompDefinitions.sol";

library Rewards {
     function calculateReward(uint256 stakedDuration) internal pure returns (uint256) {
        // Customize
        uint256 reward = stakedDuration / 60;
        return reward > 10 ? 10 : reward; // Example: +1 value per minute staked capped at 10
    }

    function levelCoefficient(uint256 level) internal pure returns (uint256) {
        level = 100 - level;
        return (1 + (level / 10)); // 10% increase per level
    }

    function rarityCoefficient(string memory rarity) internal pure returns (uint256) {
        if (compareStrings(rarity, "Legendary")) {
            return 3;
        } else if (compareStrings(rarity, "Rare")) {
            return 2;
        } else {
            return 1;
        }
    }

    function compareStrings(string memory tokenRarity, string memory rarity) internal pure returns (bool) {
        return keccak256(abi.encodePacked(tokenRarity)) == keccak256(abi.encodePacked(rarity));
    }
}

library StakeUitls {
    function isStakedByUser(StakeDefinitions.Stake[] memory userStakes, uint256 tokenId) internal pure returns (bool) {
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (userStakes[i].tokenId == tokenId) {
                return true;
            }
        }
        return false;
    }

    function findStakedIndex(StakeDefinitions.Stake[] memory ownerStakes, uint256 tokenId) internal pure returns (uint256) {
        for (uint i = 0; i < ownerStakes.length; i++) {
            if (ownerStakes[i].tokenId == tokenId) {
                return i;
            }
        }
        revert("DST: Token not found.");
    }
}

library TokenSupplyTracker {
    struct SupplyTracker {
        uint256 totalSupply;
    }

    function increment(SupplyTracker storage tracker) internal {
        tracker.totalSupply++;
    }

    function get(SupplyTracker storage tracker) internal view returns (uint256) {
        return tracker.totalSupply;
    }
}
