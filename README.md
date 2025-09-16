# Sweepnet - Street Cleaning Tracker Smart Contract System

## Overview

Sweepnet is a blockchain-based street cleaning tracker that provides proof-of-cleaning incentives using smart contracts on the Stacks blockchain. The system enables transparent verification of street cleaning activities and rewards participants with STX tokens for verified cleaning work.

## Core Features

### 🧹 Street Cleaning Management
- Register and manage street segments across urban areas
- Track cleaning schedules and requirements
- Maintain comprehensive cleaning history records
- Support for multiple cleaning types and severity levels

### 💰 Incentive System
- STX token rewards for verified cleaning activities
- Configurable reward amounts based on cleaning difficulty
- Reputation system for regular cleaners
- Performance-based bonus multipliers

### 📍 Location Tracking
- GPS coordinate-based street segment identification
- Area coverage mapping and verification
- Route optimization for cleaning efficiency
- Integration with city planning data

### ✅ Verification & Proof
- Cryptographic proof of cleaning completion
- Time-stamped activity records
- Photo evidence requirements (hash verification)
- Community-based verification system

### 👥 User Management
- Cleaner registration and profile management
- Supervisor and inspector roles
- Performance tracking and statistics
- Achievement and ranking systems

## System Architecture

The Sweepnet system consists of two main smart contracts:

### 1. Street Manager Contract (`street-manager.clar`)
- **Street Registration**: Add and configure street segments for cleaning
- **Schedule Management**: Set cleaning schedules and requirements
- **Location Management**: GPS coordinate and area management
- **Administrative Functions**: System governance and configuration

### 2. Cleaning Tracker Contract (`cleaning-tracker.clar`)
- **Cleaning Records**: Track and verify cleaning activities
- **Reward Distribution**: Process STX token payments for completed work
- **User Management**: Handle cleaner profiles and performance tracking
- **Verification System**: Validate cleaning proof and evidence

## Technical Specifications

### Smart Contract Details
- **Language**: Clarity (Stacks blockchain)
- **Token Standard**: STX native tokens
- **Security Model**: Multi-level access control with role-based permissions
- **Data Storage**: On-chain street segments and cleaning activity records

### Key Data Structures
- **Streets**: ID, name, coordinates, cleaning requirements, difficulty level
- **Cleaning Records**: Cleaner, street, timestamp, proof hash, reward amount
- **User Profiles**: Address, reputation score, total cleanings, earnings
- **Schedules**: Street assignments, frequency requirements, deadlines

## Usage Workflow

1. **Street Registration**: Administrators register street segments with cleaning requirements
2. **Cleaner Registration**: Users register as cleaners with profile creation
3. **Assignment Process**: Cleaners select or are assigned street segments to clean
4. **Cleaning Execution**: Physical cleaning work with photo documentation
5. **Proof Submission**: Upload evidence and submit cleaning completion proof
6. **Verification Process**: Community or supervisor verification of cleaning work
7. **Reward Distribution**: Automatic STX token distribution upon verification

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Stacks wallet for testing

### Installation
```bash
git clone <repository-url>
cd sweepnet
npm install
```

### Development
```bash
# Check contract syntax
clarinet check

# Run tests
npm test

# Start local development environment
clarinet console
```

## Contract Functions

### Street Manager Functions
- `register-street`: Add new street segment for cleaning
- `update-street-requirements`: Modify cleaning requirements
- `get-street-info`: Retrieve street details and status
- `set-cleaning-schedule`: Configure cleaning frequency and deadlines

### Cleaning Tracker Functions
- `register-cleaner`: Register new cleaner profile
- `submit-cleaning-proof`: Submit evidence of completed cleaning
- `verify-cleaning`: Verify and approve cleaning work
- `claim-reward`: Process reward payments for verified cleanings
- `get-cleaner-stats`: Retrieve cleaner performance statistics

## Security Features

- **Role-Based Access Control**: Separate permissions for cleaners, supervisors, and administrators
- **Input Validation**: Comprehensive validation of all user inputs and coordinates
- **Proof Integrity**: Cryptographic hashing for evidence verification
- **Reward Protection**: Safe arithmetic operations and overflow prevention
- **Anti-Fraud Measures**: Duplicate submission prevention and timing validations

## Testing

The project includes comprehensive test suites covering:
- Street registration and management
- Cleaning activity tracking and verification
- Reward calculation and distribution
- User profile management and statistics
- Edge cases and error handling
- Security and access control scenarios

## Deployment

1. Configure deployment settings in `settings/` directory
2. Deploy contracts using Clarinet to testnet/mainnet
3. Initialize system with initial street segments
4. Set up administrative permissions and roles

## Contributing

1. Fork the repository
2. Create feature branch
3. Implement changes with comprehensive tests
4. Submit pull request with detailed description

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Support

For technical support and questions:
- Create GitHub issues for bugs and feature requests
- Review documentation and contract specifications
- Join the Stacks developer community for assistance

---

**Sweepnet** - Making street cleaning transparent, efficient, and rewarding through blockchain technology.
