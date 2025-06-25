# 🏥 Healthnet - Health Worker DAO

A decentralized autonomous organization (DAO) built on Stacks blockchain to fund health worker training, certifications, and equipment through community governance.

## 🌟 Features

- 💰 **Treasury Management**: Community-funded treasury for health initiatives
- 🗳️ **Democratic Governance**: Stake-weighted voting on funding proposals
- 👩‍⚕️ **Health Worker Registry**: Track certifications, training, and equipment
- 📋 **Proposal System**: Create and vote on funding requests
- 🔒 **Secure Execution**: Automated fund distribution after successful votes

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet with STX tokens

### Installation

```bash
git clone <repository-url>
cd healthnet-dao
clarinet check
```

## 📖 Usage

### For DAO Members

#### 1. Join the DAO 💪
```clarity
(contract-call? .Healthnet join-dao u1000000)
```
Stake minimum 1 STX (1,000,000 microSTX) to become a voting member.

#### 2. Create Proposals 📝
```clarity
(contract-call? .Healthnet create-proposal 
    'SP1234... 
    u500000 
    "Nursing Certification" 
    "Fund certification for rural nurse" 
    "certification")
```

#### 3. Vote on Proposals 🗳️
```clarity
(contract-call? .Healthnet vote u1 true)
```

#### 4. Execute Passed Proposals ✅
```clarity
(contract-call? .Healthnet execute-proposal u1)
```

### For Health Workers

#### Register as Health Worker 👨‍⚕️
```clarity
(contract-call? .Healthnet register-health-worker "General Practice")
```

### For Community Supporters

#### Add Funds to Treasury 💝
```clarity
(contract-call? .Healthnet add-funds u2000000)
```

## 📊 Read-Only Functions

- `get-proposal`: View proposal details
- `get-member-stake`: Check member voting power
- `get-health-worker`: View worker credentials
- `get-treasury-balance`: Check available funds
- `is-proposal-active`: Check if voting is open

## 🏗️ Proposal Types

- **certification**: Fund professional certifications
- **training**: Support skill development programs  
- **equipment**: Provide medical equipment

## ⚙️ Configuration

- **Voting Period**: 1440 blocks (~10 days)
- **Minimum Stake**: 1 STX
- **Voting Weight**: Based on stake amount

## 🔐 Security Features

- Stake-based membership prevents spam
- Time-locked voting periods
- Single vote per member per proposal
- Automated execution only after voting ends

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Test with Clarinet
4. Submit pull request

## 📄 License

MIT License - see LICENSE file for details.

---

*Empowering health workers through decentralized funding* 🌍💙

