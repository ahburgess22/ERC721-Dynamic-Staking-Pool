// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./CompDefinitions.sol";

contract NFT {
    using TokenDefinitions for TokenDefinitions.NFT;

    event LegendaryPull(string message);

    mapping (uint256 => TokenDefinitions.NFT) private tokens;

    function createNFT(uint256 tokenId) external {
        string memory rarity = determineRarity(tokenId);
        uint8 level = calculateLevel(tokenId);

        tokens[tokenId] = TokenDefinitions.NFT({
            rarity: rarity,
            level: level
        });
    }

    function determineRarity(uint256 tokenId) internal returns (string memory) {
        if (tokenId % 100 < 10) {
            emit LegendaryPull("LEGENDARY NFT PULL!");
            return "Legendary";
        }
        else if (tokenId % 100 < 40) return "Rare";
        return "Common";
    }

    function calculateLevel(uint256 tokenId) internal pure returns (uint8) {
        return uint8(tokenId % 100);
    }

    function getToken(uint256 tokenId) external view returns (TokenDefinitions.NFT memory) {
        return tokens[tokenId];
    }
}