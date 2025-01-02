// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.20;

library BaseReward {
    function updateBaseReward() internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, address(this)))) % 100;
    }
}

library RewardRate {
    function updateRewardRate(uint256 baseReward, uint256 pools, uint256 stakes) internal pure returns(uint256) {
        if (pools > 1 && stakes > 0) { // Reward rate is 0 without a competing pool or stakes
            return (baseReward * 1e18) / (pools * stakes);
        } else {
            return 0;
        }
    }
}

library PoolWeight {
    function updatePoolStakingPower(uint256 rares, uint256 legendaries, uint256 tokens) internal pure returns(uint256) {
        tokens += (rares * 2) + (legendaries * 4);
        return tokens;
    }
}