# 💰 Scheduled Payouts to Users

A Clarity smart contract for distributing weekly earnings to users based on their share percentages. Perfect for learning about recurring distributions and time-based payouts! ⏰

## 🚀 Features

- 📅 **Weekly Distribution Cycles**: Automatic weekly payout periods based on block height
- 👥 **User Management**: Add/remove users with custom share percentages
- 💎 **Flexible Payouts**: Users can claim their earnings when available
- 🔒 **Secure Claims**: Prevents double-claiming and unauthorized access
- 📊 **Transparent Tracking**: Full visibility of pools, claims, and user stats
- 🛡️ **Owner Controls**: Emergency functions and user management

## 📋 Contract Overview

The contract operates on a weekly cycle where:
- Each week = 1008 blocks (~7 days)
- Owner funds weekly pools with STX
- Users receive payouts based on their share percentage
- Claims are available after each week completes

## 🎯 Core Functions

### 👑 Owner Functions

#### Initialize the Contract
```clarity
(contract-call? .scheduled-payouts-to-users initialize-pool)
```

#### Add a New User
```clarity
(contract-call? .scheduled-payouts-to-users add-user 'SP1234... u25)
```
*Adds user with 25% share*

#### Fund Weekly Pool
```clarity
(contract-call? .scheduled-payouts-to-users fund-weekly-pool u1000000)
```
*Funds current week with 1 STX*

#### Update User Share
```clarity
(contract-call? .scheduled-payouts-to-users update-user-share 'SP1234... u30)
```

#### Deactivate/Activate User
```clarity
(contract-call? .scheduled-payouts-to-users deactivate-user 'SP1234...)
(contract-call? .scheduled-payouts-to-users activate-user 'SP1234...)
```

### 👤 User Functions

#### Claim Single Week Payout
```clarity
(contract-call? .scheduled-payouts-to-users claim-payout u5)
```
*Claims payout for week 5*

#### Claim Multiple Weeks
```clarity
(contract-call? .scheduled-payouts-to-users claim-multiple-weeks (list u3 u4 u5))
```

### 📖 Read-Only Functions

#### Get User Information
```clarity
(contract-call? .scheduled-payouts-to-users get-user-info 'SP1234...)
```

#### Check Current Week
```clarity
(contract-call? .scheduled-payouts-to-users get-current-week)
```

#### Get Weekly Pool Data
```clarity
(contract-call? .scheduled-payouts-to-users get-weekly-pool u5)
```

#### Calculate User Payout
```clarity
(contract-call? .scheduled-payouts-to-users calculate-user-payout 'SP1234... u5)
```

#### Get Claimable Weeks
```clarity
(contract-call? .scheduled-payouts-to-users get-claimable-weeks 'SP1234...)
```

## 🔧 Setup Instructions

1. **Initialize Clarinet Project**
```bash
clarinet new scheduled-payouts
cd scheduled-payouts
```

2. **Add Contract**
   - Copy the contract code to `contracts/scheduled-payouts-to-users.clar`

3. **Deploy and Initialize**
```bash
clarinet console
```

4. **In Console - Initialize Pool**
```clarity
(contract-call? .scheduled-payouts-to-users initialize-pool)
```

## 📝 Usage Example

```clarity
;; 1. Initialize the pool (owner only)
(contract-call? .scheduled-payouts-to-users initialize-pool)

;; 2. Add users with share percentages (owner only)
(contract-call? .scheduled-payouts-to-users add-user 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u40)
(contract-call? .scheduled-payouts-to-users add-user 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9 u35)
(contract-call? .scheduled-payouts-to-users add-user 'SP1114Y1ZR3T4ST699F8PRCHH3GGHPJYQYF5FKDGF u25)

;; 3. Fund weekly pools (owner only)
(contract-call? .scheduled-payouts-to-users fund-weekly-pool u2000000)

;; 4. Users claim their payouts (after week completes)
(contract-call? .scheduled-payouts-to-users claim-payout u0)
```

## ⚠️ Important Notes

- 🕐 **Timing**: Users can only claim payouts after a week has completed
- 🚫 **No Double Claims**: Each user can only claim once per week
- 📊 **Share Percentages**: Must be between 1-100%
- 🔐 **Active Users**: Only active users can claim payouts
-

