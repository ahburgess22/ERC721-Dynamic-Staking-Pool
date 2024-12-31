// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, ERC20Capped, Ownable {
    address private _stakingContract;

    constructor(uint256 maxSupply)
        ERC20("Reward Token", "RTK")
        ERC20Capped(maxSupply)
        Ownable(msg.sender)
    { }

    function setStakingContract(address stakingContract) public onlyOwner {
        _stakingContract = stakingContract;
    }

    function _update(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._update(from, to, amount); // Calls correct parent implementation
    }

    function mint(address to, uint256 amount) public onlyStakingContract {
        require(totalSupply() + amount <= cap(), "RTK: ERC20 cap exceeded.");

        _mint(to, amount);
    }

    modifier onlyStakingContract() {
        require(msg.sender == _stakingContract, "RTK: Caller is not the staking contract");
        _;
    }
}