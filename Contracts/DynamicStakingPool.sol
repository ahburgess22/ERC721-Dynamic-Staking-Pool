// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../Helpers/StakingHelpers.sol";
import "../Helpers/CompDefinitions.sol";
import "./NFTCreator.sol";
import "./RewardToken.sol";
import "./MasterRegistry.sol";

contract DynamicStakingPool is ERC721 {

    // Libraries
    using StakeDefinitions for StakeDefinitions.Stake;
    using TokenDefinitions for TokenDefinitions.NFT;
    using TokenSupplyTracker for TokenSupplyTracker.SupplyTracker;

    // Events
    event mintedToken(address owner, uint tokenId, string rarity, uint8 level);
    event stakedToken(address owner, uint tokenId);
    event unstakedToken(address owner, uint tokenId, uint reward);
    event UserStakesUpdated(address owner, StakeDefinitions.Stake[] stakes);

    struct Account {
        uint256[] stakedNFTs;
        uint256 rewardBalance;
    }

    /* Variables */

    // Core Contracts
    NFT private nftContract; // Instance of the NFT contract
    RewardToken public rewardToken; // Instance of the RewardToken contract
    MasterRegistry public registry; // Instance of the MasterRegistry contract

    // Staking Data
    uint256 public totalStakes; // Total stakes for a given pool
    mapping(address => Account) public accounts; // User accounts (NFTs staked and reward balances)
    mapping(address => StakeDefinitions.Stake[]) public stakes; // User stakes

    // Utility
    TokenSupplyTracker.SupplyTracker private _supplyTracker; // Tracks supply-related data

    // Constructor
    constructor(address _nftCreatorAddress, address _rewardTokenAddress, address _registryAddress, string memory poolName) ERC721("Dynamic Stake Token", "DST") {
        nftContract = NFT(_nftCreatorAddress); // Set NFTCreator contract address during deployment
        rewardToken = RewardToken(_rewardTokenAddress);
        registry = MasterRegistry(_registryAddress);
        registry.registerPool(address(this), poolName);
    }

    function createToken() external {

        // Generate a unique tokenId
        uint256 tokenId = uint256(keccak256(abi.encodePacked(
            msg.sender,
            block.timestamp,
            block.prevrandao,
            _supplyTracker.get()
        )));

        nftContract.createNFT(tokenId); // Create the NFT and store metadata
        _mint(msg.sender, tokenId); // Mint the token
        TokenDefinitions.NFT memory metadata = nftContract.getToken(tokenId); // Fetch token metadata
        _supplyTracker.increment(); // Tracking total tokens in system
        emit mintedToken(msg.sender, tokenId, metadata.rarity, metadata.level);
    }

    function stake(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "DST: You must own the token to stake it.");

        // Transfer the token to the registry
        _transfer(msg.sender, address(registry), tokenId);

        // Retrieve metadata for the token
        TokenDefinitions.NFT memory metadata = nftContract.getToken(tokenId);

        // Add the stake to the user's record
        stakes[msg.sender].push(StakeDefinitions.Stake(tokenId, block.timestamp, metadata.rarity, metadata.level));
        emit UserStakesUpdated(msg.sender, stakes[msg.sender]);

        // Update total stakes
        totalStakes += 1;

        // Update registry based on token level
        if (metadata.level < 10) {
            registry.updateStakes(address(this), 1, true, false, true); // Legendary
        } else if (metadata.level < 40) {
            registry.updateStakes(address(this), 1, true, true, false); // Rare
        } else {
            registry.updateStakes(address(this), 1, true, false, false); // Common
        }

        emit stakedToken(msg.sender, tokenId);
    }

    function unstake(uint256 tokenId) external {
        require(StakeUtils.isStakedByUser(stakes[msg.sender], tokenId), "DST: Token not staked by user.");

        // Calculate rewards based on staking duration, level, and rarity
        uint256 stakedDuration = block.timestamp;
        uint256 reward = Rewards.calculateReward(stakedDuration);
        reward *= Rewards.levelCoefficient(nftContract.getToken(tokenId).level);
        reward *= Rewards.rarityCoefficient(nftContract.getToken(tokenId).rarity);

        // Transfer the NFT back to the user
        _transfer(address(registry), msg.sender, tokenId);

        // Update user's reward balance and mint the reward tokens
        accounts[msg.sender].rewardBalance += reward;
        rewardToken.mint(msg.sender, reward);

        // Remove the staked NFT
        removeStakedToken(msg.sender, tokenId);

        // Decrease the total stakes
        totalStakes -= 1;

        // Update the registry based on token level
        uint256 tokenLevel = nftContract.getToken(tokenId).level;
        if (tokenLevel < 10) {
            registry.updateStakes(address(this), 1, false, false, true); // Legendary
        } else if (tokenLevel < 40) {
            registry.updateStakes(address(this), 1, false, true, false); // Rare
        } else {
            registry.updateStakes(address(this), 1, false, false, false); // Common
        }

        // Emit the unstake event
        emit unstakedToken(msg.sender, tokenId, reward);
    }

    function removeStakedToken(address owner, uint256 tokenId) internal {
        uint256 index = StakeUtils.findStakedIndex(stakes[owner], tokenId);
        stakes[owner][index] = stakes[owner][stakes[owner].length-1]; // Moves unstaked token to end of stakes
        stakes[owner].pop(); // Removes unstaked token
    }

    function getNFTCreatorAddress() external view returns (address) {
        return address(nftContract);
    }

    function getUserStakes() public view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](stakes[msg.sender].length);
        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            tokenIds[i] = stakes[msg.sender][i].tokenId;
        }
        return tokenIds;
        }

    function getRewardBalance(address user) public view returns (uint256) {
        return accounts[user].rewardBalance;
    }
}