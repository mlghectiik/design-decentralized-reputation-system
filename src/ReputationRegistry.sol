// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ReputationRegistry
 * @dev Core contract for managing decentralized reputation scores
 * @notice This contract stores and calculates reputation scores with anti-gaming mechanisms
 */
contract ReputationRegistry is Ownable, ReentrancyGuard {
    // Constants for reputation calculations
    uint256 public constant MAX_REPUTATION = 1000;
    uint256 public constant MIN_REPUTATION = 0;
    uint256 public constant INITIAL_REPUTATION = 500;
    uint256 public constant REPUTATION_DECAY_RATE = 1; // 0.1% per decay period
    uint256 public constant DECAY_PERIOD = 30 days;

    // Structs
    struct ReputationData {
        uint256 score; // Current reputation score (0-1000)
        uint256 totalRatings; // Total number of ratings received
        uint256 totalScore; // Sum of all ratings (for average calculation)
        uint256 lastUpdateTime; // Timestamp of last reputation update
        uint256 lastDecayTime; // Timestamp of last decay application
        bool isRegistered; // Whether user is registered in the system
    }

    struct RatingWeight {
        uint256 raterReputation; // Reputation of the person giving the rating
        uint256 weight; // Calculated weight for this rating
    }

    // State variables
    mapping(address => ReputationData) private _reputations;
    mapping(address => bool) public authorizedRaters;
    address[] private _registeredUsers;

    // Reputation calculation parameters
    uint256 public minRaterReputation = 300; // Minimum reputation to give weighted ratings
    uint256 public maxWeightMultiplier = 200; // Max weight multiplier (2x)

}
