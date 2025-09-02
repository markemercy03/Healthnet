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

## 🏆 Health Worker Reputation System

The Healthnet DAO includes a comprehensive reputation system for health workers that tracks and rewards their contributions to the platform.

### Features

- **Reputation Scoring**: Workers earn points for submitting health metrics (+5 points) and verifying reports (+3 points)
- **Level Progression**: Five reputation levels based on scores:
  - Beginner: 0-25 points
  - Contributor: 26-75 points
  - Expert: 76-150 points
  - Master: 151-300 points
  - Champion: 300+ points
- **Bonus Rewards**: Workers with 100+ reputation can claim periodic bonuses (1000 STX per reputation point)
- **Activity Tracking**: Monitors metrics submitted, verifications completed, and last activity

### Functions

#### Public Functions
- `claim-reputation-bonus()` - Claim periodic STX bonus based on reputation (requires 100+ reputation, 10-day cooldown)
- `verify-health-metric-with-reputation(report-id)` - Verify metrics while earning reputation points

#### Read-Only Functions
- `get-worker-reputation(worker)` - Get complete reputation data for a worker
- `get-reputation-level(worker)` - Get the reputation level string for a worker
- `calculate-reputation-bonus(worker)` - Calculate potential bonus amount for a worker

### Integration

The reputation system is seamlessly integrated into existing workflows:
- Health metric submissions automatically update worker reputation
- Metric verification through the new reputation-aware function grants verifier reputation points
- Reputation bonuses provide long-term incentives for consistent participation

---

*Empowering health workers through decentralized funding* 🌍💙

