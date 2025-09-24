# Medical Research Grant Smart Contract

A decentralized research funding smart contract built on the Stacks blockchain that enables transparent, community-driven medical research funding and governance.

## Overview

This smart contract facilitates medical research funding through a decentralized approach where:
- Lead researchers can initiate studies and set funding targets
- Community stakeholders can contribute funds to support research
- Peer review processes determine trial phase approvals
- Automatic refund mechanisms protect stakeholders if funding targets aren't met

## Key Features

### 🔬 Research Management
- **Study Initiation**: Researchers can create new studies with specific funding targets and timelines
- **Multi-Phase Trials**: Support for multiple trial phases with individual protocols and budgets
- **Status Tracking**: Real-time monitoring of research progress and funding status

### 💰 Decentralized Funding
- **Community Funding**: Stakeholders can contribute STX tokens to support research
- **Funding Targets**: Clear funding goals with automatic target validation
- **Refund Protection**: Automatic refunds if studies don't reach funding targets

### 🗳️ Peer Review System
- **Weighted Voting**: Review votes are weighted by funding contributions
- **Democratic Approval**: Trial phases require majority approval to proceed
- **Transparent Process**: All reviews and decisions are recorded on-chain

## Contract Architecture

### Data Variables
- `lead-researcher`: Principal address of the research lead
- `grant-target`: Total funding target amount
- `funds-allocated`: Current amount of funds raised
- `research-status`: Current study status ("not_started", "recruiting", "peer_review")
- `study-end-block`: Block height when study period ends

### Maps
- `reviewer-contributions`: Tracks individual stakeholder contributions
- `trial-phases`: Stores protocol details and budgets for each trial phase

## Public Functions

### Study Management

#### `initiate-research-study`
```clarity
(initiate-research-study (grant-amount uint) (study-period uint))
```
Initiates a new research study with specified funding target and timeline.
- **Parameters**: 
  - `grant-amount`: Target funding amount in microSTX
  - `study-period`: Study duration in blocks (max 52,560 blocks ≈ 1 year)
- **Access**: Anyone (becomes lead researcher)

#### `define-trial-phase`
```clarity
(define-trial-phase (protocol string-utf8) (budget uint))
```
Defines a new trial phase with protocol description and budget.
- **Access**: Lead researcher only

### Funding Operations

#### `fund-research`
```clarity
(fund-research (amount uint))
```
Allows stakeholders to contribute funding to active research.
- **Parameters**: `amount` - Amount to contribute in microSTX
- **Access**: Anyone during active study period

#### `disburse-grant-funds`
```clarity
(disburse-grant-funds (amount uint))
```
Allows lead researcher to withdraw approved funds.
- **Access**: Lead researcher only

#### `claim-research-refund`
```clarity
(claim-research-refund)
```
Enables stakeholders to claim refunds if study fails to reach funding target.
- **Access**: Contributors after study period ends

### Review Process

#### `start-peer-review`
```clarity
(start-peer-review)
```
Initiates peer review phase for current trial.
- **Access**: Lead researcher only

#### `review-trial-phase`
```clarity
(review-trial-phase (approve bool))
```
Submit review vote for current trial phase.
- **Parameters**: `approve` - true for approval, false for rejection
- **Access**: Contributors only (weighted by contribution)

#### `conclude-peer-review`
```clarity
(conclude-peer-review)
```
Finalizes review process and determines trial outcome.
- **Access**: Lead researcher only

## Read-Only Functions

### `get-research-overview`
Returns comprehensive study information including researcher, targets, and current status.

### `get-reviewer-contribution`
```clarity
(get-reviewer-contribution (reviewer principal))
```
Returns contribution amount for a specific reviewer.

### `get-trial-details`
```clarity
(get-trial-details (trial-id uint))
```
Returns protocol and budget information for a specific trial phase.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR_NOT_LEAD_RESEARCHER | Action requires lead researcher privileges |
| u101 | ERR_STUDY_ALREADY_INITIATED | Study has already been started |
| u102 | ERR_REVIEWER_NOT_FOUND | Reviewer has not contributed to study |
| u103 | ERR_STUDY_PERIOD_ENDED | Study funding period has expired |
| u104 | ERR_GRANT_TARGET_UNMET | Funding target not yet reached |
| u105 | ERR_INSUFFICIENT_GRANT_FUNDS | Not enough funds available for withdrawal |
| u106 | ERR_INVALID_FUNDING_AMOUNT | Invalid funding amount (must be > 0) |
| u107 | ERR_INVALID_STUDY_PERIOD | Invalid study period (1-52560 blocks) |
| u408 | ERR_TRIAL_REJECTED | Trial phase rejected by peer review |
| u409 | ERR_INVALID_PROTOCOL | Protocol description too long (>256 chars) |

## Usage Examples

### Starting a Research Study
```clarity
;; Initiate a study with 1000 STX target, 10000 block duration
(contract-call? .medical-research initiate-research-study u1000000000 u10000)
```

### Contributing to Research
```clarity
;; Fund research with 100 STX
(contract-call? .medical-research fund-research u100000000)
```

### Peer Review Process
```clarity
;; Start peer review
(contract-call? .medical-research start-peer-review)

;; Submit approval vote
(contract-call? .medical-research review-trial-phase true)

;; Conclude review
(contract-call? .medical-research conclude-peer-review)
```

## Security Considerations

- **Access Control**: Functions are properly restricted to authorized users
- **Funding Protection**: Automatic refunds protect stakeholder investments
- **Validation**: Input validation prevents invalid funding amounts and periods
- **State Management**: Proper state transitions prevent unauthorized actions

## Deployment Requirements

- Stacks blockchain
- Clarity smart contract runtime
- Sufficient STX for contract deployment and operations

## Contributing

This is a demonstration smart contract for educational purposes. For production use, additional features and security audits would be recommended:

- Multi-signature requirements for large fund disbursements
- Time-locked fund release mechanisms  
- Integration with external research validation systems
- Enhanced governance mechanisms
- Detailed audit trails and reporting
