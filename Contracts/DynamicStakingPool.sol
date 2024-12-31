// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StakingHelpers.sol";
import "./CompDefinitions.sol";
import "./NFTCreator.sol";
import "./RewardToken.sol";

contract DynamicStakingPool is ERC721, Ownable, IERC721Receiver {
    using StakeDefinitions for StakeDefinitions.Stake;
    using TokenDefinitions for TokenDefinitions.NFT;
    using TokenSupplyTracker for TokenSupplyTracker.SupplyTracker;

    event mintedToken(address owner, uint tokenId, string rarity, uint8 level);
    event stakedToken(address owner, uint tokenId);
    event unstakedToken(address owner, uint tokenId, uint rewardId);

    struct Account {
        uint256[] stakedNFTs;
        uint256 rewardBalance;
    }
    mapping(address => Account) public accounts;
    TokenSupplyTracker.SupplyTracker private _supplyTracker;
    DynamicNFT private nftContract; // Instance of the NFTCreator contract
    RewardToken public rewardToken;
    address private bank;
    mapping(address => StakeDefinitions.Stake[]) public stakes;

    constructor(address _nftCreatorAddress, address _rewardTokenAddress) ERC721("Dynamic Stake Token", "DST") Ownable(msg.sender) {
        nftContract = DynamicNFT(_nftCreatorAddress); // Set NFTCreator contract address during deployment
        rewardToken = RewardToken(_rewardTokenAddress);
        bank = 0x1234567890123456789012345678901234567890;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function createToken(address to) external {

        // Generate a unique tokenId
        uint256 tokenId = uint256(keccak256(abi.encodePacked(
            to,
            block.timestamp,
            block.prevrandao,
            _supplyTracker.get()
        )));

        nftContract.createNFT(tokenId); // Create the NFT and store metadata
        _mint(to, tokenId); // Mint the token
        TokenDefinitions.NFT memory metadata = nftContract.getToken(tokenId); // Fetch token metadata
        _supplyTracker.increment(); // Tracking total tokens in system
        emit mintedToken(to, tokenId, metadata.rarity, metadata.level);
    }

    function stake(address account, uint256 tokenId) external {
        require(ownerOf(tokenId) == account, "DST: You must own the token to stake it.");

        _transfer(account, bank, tokenId);
        TokenDefinitions.NFT memory metadata = nftContract.getToken(tokenId);
        stakes[account].push(StakeDefinitions.Stake(tokenId, block.timestamp, metadata.rarity, metadata.level));
        emit stakedToken(account, tokenId);
    }

    function unstake(address account, uint256 tokenId) external {
        require(StakeUitls.isStakedByUser(stakes[account], tokenId), "DST: Token not staked by user.");

        uint256 stakedDuration = block.timestamp;
        uint256 reward = Rewards.calculateReward(stakedDuration);
        _transfer(bank, account, tokenId);

        accounts[account].rewardBalance += reward;
        rewardToken.mint(account, reward);
        removeStakedToken(account, tokenId);
        emit unstakedToken(account, tokenId, reward);
    }

    function removeStakedToken(address owner, uint256 tokenId) internal {
        uint256 index = StakeUitls.findStakedIndex(stakes[owner], tokenId);
        stakes[owner][index] = stakes[owner][stakes[owner].length-1]; // Moves unstaked token to end of stakes
        stakes[owner].pop(); // Removes unstaked token
    }

    function getNFTCreatorAddress() external view returns (address) {
        return address(nftContract);
    }
}