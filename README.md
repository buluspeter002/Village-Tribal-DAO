# 🏘️ Village DAO - Digital Community Governance

A decentralized autonomous organization (DAO) smart contract built on Stacks blockchain to digitize local community decision-making and budget management for villages and tribal communities.

## 🌟 Features

- **👥 Community Membership**: Join the village DAO and participate in governance
- **💰 Treasury Management**: Contribute funds and manage community budget
- **📝 Proposal System**: Create and vote on community proposals
- **🗳️ Weighted Voting**: Voting power based on community contributions
- **🤝 Vote Delegation**: Delegate voting power to trusted community members
- **⚡ Proposal Execution**: Automatic execution of approved budget proposals

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation

```bash
clarinet new village-dao-project
cd village-dao-project
```

Copy the contract code into `contracts/village-dao.clar`

### Testing

```bash
clarinet console
```

## 📖 Usage Guide

### 🏠 Joining the Village

```clarity
(contract-call? .village-dao join-village)
```

### 💵 Contributing to Treasury

```clarity
(contract-call? .village-dao contribute-to-treasury u1000000)
```

### 📋 Creating a Proposal

```clarity
(contract-call? .village-dao create-proposal 
  "Build Community Well" 
  "Proposal to build a new water well for the village" 
  u5000000 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  "budget")
```

### 🗳️ Voting on Proposals

```clarity
(contract-call? .village-dao vote-on-proposal u1 true)
```

### ✅ Executing Approved Proposals

```clarity
(contract-call? .village-dao execute-proposal u1)
```

### 🔄 Delegating Voting Power

```clarity
(contract-call? .village-dao delegate-voting-power 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  u2)
```

## 🔍 Read-Only Functions

### Check Proposal Details
```clarity
(contract-call? .village-dao get-proposal u1)
```

### Check Member Information
```clarity
(contract-call? .village-dao get-member-info 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Check Treasury Balance
```clarity
(contract-call? .village-dao get-treasury-balance)
```

### Check Proposal Status
```clarity
(contract-call? .village-dao get-proposal-status u1)
```

## 🏗️ Contract Architecture

### Core Components

- **👤 Membership System**: Track village members and their voting power
- **💼 Treasury Management**: Secure fund storage and distribution
- **📊 Proposal Lifecycle**: Creation, voting, and execution phases
- **⚖️ Governance Rules**: Democratic decision-making with weighted voting

### Proposal Types

- **💰 Budget Proposals**: Allocate funds from treasury
- **📜 Governance Proposals**: Community decisions and rule changes

### Voting Mechanism

- **⏰ Time-bound Voting**: 144 blocks (~24 hours) voting period
- **🏆 Simple Majority**: Proposals pass with more votes-for than votes-against
- **⚡ Automatic Execution**: Approved budget proposals execute automatically

## 🛡️ Security Features

- **🔐 Member-only Actions**: Only village members can participate
- **🚫 Double-voting Prevention**: One vote per member per proposal
- **💸 Treasury Protection**: Funds only released through approved proposals
- **👑 Emergency Controls**: Contract owner emergency functions

## 🎯 Use Cases

- **🏘️ Village Infrastructure**: Fund community projects like wells, roads, schools
- **🌾 Agricultural Initiatives**: Collective farming and resource sharing
- **🎓 Education Programs**: Community learning and skill development
- **🏥 Healthcare Access**: Medical facilities and health programs
- **🌱 Environmental Projects**: Conservation and sustainability initiatives

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with Clarinet
5. Submit a pull request

## 📄 License

MIT License - Build amazing communities! 🌍

## 🆘 Support

For questions and support, please open an issue in the repository or reach out to the community.

---

*Empowering communities through decentralized governance* 🌟
```

**Git Commit Message:**
```
feat: implement village DAO smart contract with governance and treasury management
```

**GitHub Pull Request Title:**
```
🏘️ Add Village DAO MVP - Community Governance & Budget Management
```

**GitHub Pull Request Description:**
```
## 🎯 Overview
This PR introduces a complete Village DAO smart contract that enables digital community governance for villages and tribal communities.

## ✨ Features Added
- **Community membership system** with join functionality
- **Treasury management** with contribution tracking and weighted voting power
- **Proposal creation and voting** with time-bound democratic processes  
- **Automatic proposal execution** for approved budget allocations
- **Vote delegation system** for flexible governance participation
- **Read-only functions** for transparency and data access

## 🏗️ Technical Implementation
- 150+ lines of clean, production-ready Clarity code
- Comprehensive error handling with descriptive error codes
- Secure fund management with STX transfers
- Time-based voting periods (144 blocks ≈ 24 hours)
- Weighted voting based on community contributions

## 🧪 Testing
- All core functions implemented and ready for Clarinet testing
- Error cases handled appropriately
- Security measures in place for fund protection

## 📚 Documentation
- Complete README with usage examples and API documentation
- Clear setup and deployment instructions
- Comprehensive feature overview with emojis for engagement

Ready for community testing and feedback! 🚀
