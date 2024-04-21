# 🌉 HabibiCross 🏃

## 🎯 About
HabibiCross seamlessly connects achievements with cryptocurrency rewards. By linking your digital wallet, you can effortlessly track your progress and claim rewards in USDC on your preferred blockchain, all without any transaction fees.


## 🔗 Smart Contract Deployment Addresses
- **Sepolia ETH:** `0x2D2B9Bf62b0143a8D68eD4A7063E5F50244dFC81`
- **Base:** `0x54d562B3a8b680F8a21D721d22f0BB58A3787555`
- **Morph:** `0x338607A7d733D1B37c902028225d529dd5DC000C`
- **XDC:** ``

## 🛠 Technologies Used
- Next.js
- Node.js
- Solidity
- Ethereum
- Chainlink
- Morph
- XDC
- Web3.js

## 🎁 Features
- **Wallet Connection:** Easily connect and manage your cryptocurrency wallet using social auth.
- **Achievement Tracking:** Set and track milestones that, when achieved, trigger cryptocurrency rewards.
- **Direct Payouts:** Receive USDC directly to your wallet.
- **No Transaction Fees:** Enjoy the full value of your rewards without any deductions.

## 📜 The Problem It Solves
HabibiCross eliminates the gap between effort and monetary reward. Our platform allows users to gain tangible benefits from their activities, effectively monetizing their efforts in a secure, fee-free environment.

## 🐞 Challenges We Ran Into

### Chainlink Functions - ABI Encoding/Decoding
- **Challenge:** Our project used Chainlink functions that gave back many values. This made it hard to handle data between requests not on the blockchain and responses on the blockchain.
- **Solution:** We made strong functions for encoding and decoding that kept the data accurate and intact. We also used Chainlink’s own guides and tests to make sure everything worked right.

### Biconomy Account Abstraction
- **Challenge:** Adding Biconomy's account abstraction led to many bugs, especially with handling transactions that Biconomy was supposed to pay for.
- **Solution:** We followed Biconomy’s instructions carefully, spent a lot of time fixing bugs, and improved how we handle errors to make sure transactions went smoothly.

### Chainlink CCIP - Liquidity Management for Reward Tokens
- **Challenge:** We used Chainlink CCIP to manage tokens that give rewards, but it was hard to handle these tokens because Chainlink didn’t support them fully.
- **Solution:** We used Chainlink's messaging system to manage and move these tokens effectively.

### Morph/XDC Support - Bridge Liquidity Management
- **Challenge:** There was no existing bridge support for Morph/XDC, which made it tough to manage how money was moved.
- **Solution:** We built our own bridge to help move money and started supporting these networks.


## 📈 Future Enhancements
- Expand support for additional cryptocurrencies and blockchains.
- Integrate more personalized achievement tracking options.
- Enhance user interface for even smoother interactions.

## 🤝 Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## ⚖️ License
Distributed under the MIT License. See `LICENSE` for more information.


Project Link: [https://gamers-reward-portal.vercel.app/](https://gamers-reward-portal.vercel.app/)


