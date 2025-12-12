#Collateralized Loan Smart Contract – Hardhat Project

This project implements and deploys a simple Collateralized Loan smart contract using Solidity and Hardhat. It includes the Solidity contract, automated tests, and a deployment script. The contract is successfully deployed on the Ethereum Sepolia Testnet.

Contract Information

Contract Name: CollateralizedLoan

Sepolia Contract Address: 0x2c548Fa641e23AD8CEfEf94bbBf632E850De8519

Etherscan Link:
https://sepolia.etherscan.io/address/0x2c548Fa641e23AD8CEfEf94bbBf632E850De8519

Project Structure
contracts/
   CollateralizedLoan.sol

test/
   CollateralizedLoan.js

scripts/
   deploy.js

hardhat.config.js

Running Tests
npx hardhat test

Deploying to Sepolia
npx hardhat run scripts/deploy.js --network sepolia

Notes for my Reviewer

The contract compiles without errors.

All provided tests pass.

Deployment to Sepolia was successful and the contract address is included above.