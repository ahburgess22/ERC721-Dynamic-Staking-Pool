# ERC721-Dynamic-Staking-Pool
A Solidity-based smart contract for a dynamic staking pool that utilizes ERC721 tokens to enable secure and variable-reward staking mechanisms.

## Project Overview
Dynamic Staking Pool (DSP) is an advanced staking decentralized application (dApp) designed to integrate dynamic NFTs with staking rewards. This system introduces fairness and transparency by providing:
- **Dynamic NFTs**: NFTs with rarity and level attributes that influence staking rewards.
- **Fair Staking Rewards**: Rewards calculated based on staking duration, NFT rarity, and level.
- **Rarity Bonuses**: Rare and Legendary NFTs yield higher staking power and increased rewards.

The dApp is modular, ensuring extensibility and ease of integration into future blockchain ecosystems.

## Tech Stack
- **Solidity**: Core language for smart contarcts.
- **Hardhat**: Development environment and testing framework.
- **Ethers.js**: Library for blockchain interaction.
- **OpenZeppelin**: Secure and battle-tested ERC721 and ERC20 standards.
- **Remix IDE**: Userd for initial contract deployment and testing

## Architecture Diagram
<img width="912" alt="Screenshot 2025-01-05 at 10 38 06 PM" src="https://github.com/user-attachments/assets/e2cb444f-47c5-4532-9909-52147646cf05" />
This diagram illustrates the data flow and interaction within a single staking pool in the Dynamic Staking Pool (DSP) system. Users deploy their unique DSP contract, mint NFTs with specific rarity and level attributes, and stake them to accumulate staking power. The Master Registry acts as the global source of truth, aggregating data from all deployed DSP contracts to calculate global staking power and facilitate competition among pools for the validator lottery. Each pool competes to win rewards by maximizing its staking power, providing an engaging and fair staking ecosystem. Imagine multiple DSPs interacting with the Master Registry, where pools dynamically adjust their strategies to maximize their rewards.

## Setup & Dependencies
#### Prereqruisites
- Node.js and npm installed
- MetaMask wallet configured for a testnet (e.g., Goerli).
- Hardhat installed globally.

#### Setup Instructions
1. Clone the repo
2. Install dependencies
   - npm install
3. Compile smart contracts
   - npx hardhat compile
4. Run tests to verify functionality
   - npx hardhat test
5. Deploy contracts to a testnet
   - npx hardhat run scripts/deploy.js --network goerli

#### Frontend Integration
- Ensure your frontend connects to the deployed contract addresses.
- Use Ethers.js to call functions like _stake_, _unstake_, and _getUserStakes_.

## Features
#### Staking
- Users can stake NFTs by calling _stake(tokenId)_.
- The NFT's rarity and level are recorded in the MasterRegistry for reward calculations.

#### Unstaking
- Unstaking an NFT retrieves the original NFT and mints reward tokens based on the staking duration and NFT attributes.

#### Reward Calculations
- Rewards are dynamically calculated based on:
    - **Duration**: Difference between the staking and unstaking timestamps.
    - **Rarity Bonus**: Increased staking power for Rare and Legendary NFTs.
    - **Level Coefficients**: Higher-level NFTs yield higher rewards.

#### MasterRegistry
- Tracks global staking data, including:
  - Total stakes per pool.
  - Rare and Legendary NFT counts.
  - Updates global reward rates based on staking activity.

#### RewardToken
- ERC20-compliant token with capped supply.
- Only authorized DSP contracts cna mint reward tokens.

## Future Plans
1. Frontend Development:
   - Build user-friendly interfaces for staking, unstaking, and dashboard analytics.
2. Deployment to Mainnet:
   - After thorough testing on Goerli, migrate the dApp to Ethereum mainnet.
  
## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any suggestions or improvements.

## License
This project is licensed under the MIT License. See the LICENSE file for details.
