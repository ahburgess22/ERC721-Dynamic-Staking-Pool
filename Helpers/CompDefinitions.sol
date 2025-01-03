// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library StakeDefinitions {
    struct Stake {
        uint256 tokenId;
        uint256 stakingTime;
        string rarity;
        uint8 level;
    }
}

library TokenDefinitions {
    struct NFT {
        string rarity;
        uint8 level;
    }
}