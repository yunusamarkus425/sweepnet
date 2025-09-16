# Street Cleaning Tracker Smart Contracts

## Overview
This pull request introduces the complete smart contract implementation for **Sweepnet**, a blockchain-based street cleaning tracker that provides proof-of-cleaning incentives on the Stacks blockchain.

## Changes

### Smart Contracts Added
- **`street-manager.clar`** (254 lines) - Manages street segments, schedules, and administrative controls
- **`cleaning-tracker.clar`** (351 lines) - Handles cleaning activities, verification, and reward distribution

### Key Features

#### Street Management System
- Register street segments with GPS coordinates
- Configure cleaning schedules and difficulty levels
- Administrative controls for street activation/deactivation
- Anti-spam validation for location data and naming

#### Cleaning Tracking & Verification
- User registration system for cleaners
- Proof-of-cleaning submission with SHA256 hash verification
- Community-based verification workflow
- Reputation scoring system (0-1000 scale)
- Anti-fraud protection with timing validations

#### Reward Distribution
- STX token-based incentive system
- Dynamic reward calculation based on:
  - Base reward amount (configurable)
  - Difficulty multipliers for challenging areas
  - Reputation bonuses for experienced cleaners
- Safe reward claiming with verification requirements

### Security Features
- Role-based access control for admins and cleaners
- Input validation for coordinates, names, and amounts
- Protection against duplicate cleaning submissions
- Emergency pause functionality
- Safe arithmetic operations throughout

### Architecture Highlights
- **No cross-contract dependencies** - Self-contained design
- **Comprehensive error handling** - 20+ specific error codes
- **Gas optimization** - Efficient data structures and operations
- **Future-proof design** - Extensible reward and verification systems

## Contract Functions

### Street Manager (17 public functions)
- Street registration and management
- Admin permission controls
- System configuration and statistics

### Cleaning Tracker (11 public functions)
- Cleaner registration and profile management
- Cleaning proof submission and verification
- Reward calculation and distribution
- Contract funding and emergency controls

## Testing & Validation

✅ **Clarinet Check**: All contracts pass syntax validation  
✅ **Type Safety**: Proper Clarity type usage throughout  
✅ **Error Handling**: Comprehensive error coverage  
✅ **Security**: Input validation and access controls implemented

## Code Quality Metrics
- **Total Lines**: 605 lines of production Clarity code
- **Test Coverage**: Full test suite included
- **Documentation**: Comprehensive inline comments
- **Maintainability**: Clean, readable code structure

## Deployment Ready
The contracts are fully prepared for testnet/mainnet deployment with proper configuration files and deployment scripts included.

## Impact
This implementation enables transparent, blockchain-verified street cleaning with economic incentives, promoting community engagement in urban maintenance through proven cryptographic methods.
