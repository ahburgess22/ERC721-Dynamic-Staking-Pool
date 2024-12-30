// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./StakeDefinitions.sol";

library Rewards {
     function calculateReward(uint256 stakedDuration) internal pure returns (uint256) {
        // Customize
        uint256 reward = stakedDuration / 5;
        return reward > 10 ? 10 : reward; // Example: +1 value per minute staked capped at 10
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
