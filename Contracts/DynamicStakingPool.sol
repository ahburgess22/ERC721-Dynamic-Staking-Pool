// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./StakingHelpers.sol";
import "./CompDefinitions.sol";
import "./NFTCreator.sol";
import "./RewardToken.sol";
import "./MasterRegistry.sol";

contract DynamicStakingPool is ERC721 {
    using StakeDefinitions for StakeDefinitions.Stake;
    using TokenDefinitions for TokenDefinitions.NFT;
    using TokenSupplyTracker for TokenSupplyTracker.SupplyTracker;

    event mintedToken(address owner, uint tokenId, string rarity, uint8 level);
    event stakedToken(address owner, uint tokenId);
    event unstakedToken(address owner, uint tokenId, uint reward);

    struct Account {
        uint256[] stakedNFTs;
        uint256 rewardBalance;
    }
    mapping(address => Account) public accounts;
    TokenSupplyTracker.SupplyTracker private _supplyTracker;
    NFT private nftContract; // Instance of the NFTCreator contract
    RewardToken public rewardToken;
    MasterRegistry public registry;
    uint256 public totalStakes;
    mapping(address => StakeDefinitions.Stake[]) public stakes;

    constructor(address _nftCreatorAddress, address _rewardTokenAddress, address _registryAddress, string memory poolName) ERC721("Dynamic Stake Token", "DST") {
        nftContract = NFT(_nftCreatorAddress); // Set NFTCreator contract address during deployment
        rewardToken = RewardToken(_rewardTokenAddress);
        registry = MasterRegistry(_registryAddress);
        registry.registerPool(address(this), poolName);
    }

    // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4) {
    //     return this.onERC721Received.selector;
    // }

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

        _transfer(msg.sender, address(registry), tokenId);
        TokenDefinitions.NFT memory metadata = nftContract.getToken(tokenId);
        stakes[msg.sender].push(StakeDefinitions.Stake(tokenId, block.timestamp, metadata.rarity, metadata.level));
        totalStakes += 1;
        registry.updateStakes(address(this), 1, true);
        emit stakedToken(msg.sender, tokenId);
    }

    function unstake(uint256 tokenId) external {
        require(StakeUitls.isStakedByUser(stakes[msg.sender], tokenId), "DST: Token not staked by user.");

        uint256 stakedDuration = block.timestamp;
        uint256 reward = Rewards.calculateReward(stakedDuration);
        reward *= Rewards.levelCoefficient(nftContract.getToken(tokenId).level);
        reward *= Rewards.rarityCoefficient(nftContract.getToken(tokenId).rarity);
        _transfer(address(registry), msg.sender, tokenId);

        accounts[msg.sender].rewardBalance += reward;
        rewardToken.mint(msg.sender, reward);
        removeStakedToken(msg.sender, tokenId);
        totalStakes -= 1;
        registry.updateStakes(address(this), 1, false);
        emit unstakedToken(msg.sender, tokenId, reward);
    }

    function removeStakedToken(address owner, uint256 tokenId) internal {
        uint256 index = StakeUitls.findStakedIndex(stakes[owner], tokenId);
        stakes[owner][index] = stakes[owner][stakes[owner].length-1]; // Moves unstaked token to end of stakes
        stakes[owner].pop(); // Removes unstaked token
    }

    function getNFTCreatorAddress() external view returns (address) {
        return address(nftContract);
    }

    function getUserStakes(address user) public view returns (StakeDefinitions.Stake[] memory) {
        return stakes[user];
    }

    function getRewardBalance(address user) public view returns (uint256) {
        return accounts[user].rewardBalance;
    }
}