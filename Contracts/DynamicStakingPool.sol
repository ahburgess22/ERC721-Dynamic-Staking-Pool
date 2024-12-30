// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StakingHelpers.sol";
import "./StakeDefinitions.sol";

contract DynamicStakingPool is ERC721, Ownable, IERC721Receiver {
    using StakeDefinitions for StakeDefinitions.Stake;

    event stakedToken(address owner, uint tokenId);
    event unstakedToken(address owner, uint tokenId, uint rewardId);

    struct Config {
        uint256 tokenId;
    }
    Config public config = Config(1);

    address public immutable bank = 0x1234567890123456789012345678901234567890;
    mapping (address => StakeDefinitions.Stake[]) public stakes;
    mapping (uint => uint) public tokenStakingStart;

    constructor() ERC721("Dynamic Stake Token", "DST") Ownable(msg.sender) { }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function createToken(address to) external {
        uint next_token = config.tokenId++;
        _mint(to, next_token);
    }

    function stake(address account, uint256 tokenId) external {
        require(ownerOf(tokenId) == account, "DST: You must own the token to stake it.");

        _transfer(account, bank, tokenId);
        stakes[account].push(StakeDefinitions.Stake(tokenId, block.timestamp));
        tokenStakingStart[tokenId] = block.timestamp;
        emit stakedToken(account, tokenId);
    }

    function unstake(address account, uint256 tokenId) external {
        require(StakeUitls.isStakedByUser(stakes[account], tokenId), "DST: Token not staked by user.");

        uint256 stakedDuration = block.timestamp - tokenStakingStart[tokenId];
        uint256 reward = Rewards.calculateReward(stakedDuration);
        _transfer(bank, account, tokenId);
        _mint(account, reward);
        removeStakedToken(account, tokenId);
        emit unstakedToken(account, tokenId, reward);
    }

    function removeStakedToken(address owner, uint256 tokenId) internal {
        uint256 index = StakeUitls.findStakedIndex(stakes[owner], tokenId);
        stakes[owner][index] = stakes[owner][stakes[owner].length-1]; // Moves unstaked token to end of stakes
        stakes[owner].pop(); // Removes unstaked token
    }
}