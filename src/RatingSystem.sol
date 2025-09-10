// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

interface IReputationRegistry {
    function getReputation(address user) external view returns (uint256);
    function updateReputation(address user, uint256 rating, address rater) external;
    function getReputationData(address user) external view returns (
        uint256 score,
        uint256 totalRatings,
        uint256 totalScore,
        uint256 lastUpdateTime,
        uint256 lastDecayTime,
        bool isRegistered
    );
}

/**
 * @title RatingSystem
 * @dev Handles rating submissions between users with anti-gaming mechanisms
 * @notice This contract manages the rating process and enforces business rules
 */
contract RatingSystem is Ownable, ReentrancyGuard, Pausable {
    // Constants
    uint256 public constant MIN_RATING = 1;
    uint256 public constant MAX_RATING = 1000;
    uint256 public constant DEFAULT_COOLDOWN = 24 hours;
    uint256 public constant MAX_RATINGS_PER_PAIR = 5; // Max ratings between same users

    // Enums
    enum RatingCategory {
        OVERALL,
        COMMUNICATION,
        RELIABILITY,
        QUALITY,
        TIMELINESS
    }

    enum RatingContext {
        GENERAL,
        TRANSACTION,
        SERVICE,
        COLLABORATION,
        OTHER
    }

    // Structs
    struct Rating {
        address rater;           // Address of user giving the rating
        address ratee;           // Address of user being rated
        uint256 score;           // Rating score (1-1000)
        RatingCategory category; // Category of rating
        RatingContext context;   // Context of the interaction
        string comment;          // Optional comment (IPFS hash recommended)
        uint256 timestamp;       // When rating was submitted
        bool isActive;           // Whether rating is still valid
        uint256 blockNumber;     // Block number for verification
    }

    struct UserRatingStats {
        uint256 totalRatingsGiven;
        uint256 totalRatingsReceived;
        uint256 averageGiven;
        uint256 averageReceived;
        uint256 lastRatingTime;
    }

    struct RatingLimits {
        uint256 cooldownPeriod;     // Time between ratings of same user
        uint256 maxRatingsPerDay;   // Max ratings a user can give per day
        uint256 minReputationToRate; // Minimum reputation required to rate
        bool requireMinReputation;   // Whether to enforce min reputation
    }

    // State variables
    IReputationRegistry public immutable reputationRegistry;

    // Storage
    mapping(uint256 => Rating) public ratings;
    mapping(address => UserRatingStats) public userStats;
    mapping(address => mapping(address => uint256[])) public userRatingHistory; // rater => ratee => rating IDs
    mapping(address => mapping(address => uint256)) public lastRatingTime; // rater => ratee => timestamp
    mapping(address => uint256[]) public ratingsGivenByUser;
    mapping(address => uint256[]) public ratingsReceivedByUser;
    mapping(address => mapping(uint256 => uint256)) public dailyRatingCount; // user => day => count

    constructor(
        address _reputationRegistry,
        address _owner
    ) Ownable(_owner) {
        reputationRegistry = IReputationRegistry(_reputationRegistry);
        
        // Set default rating limits
        ratingLimits = RatingLimits({
            cooldownPeriod: DEFAULT_COOLDOWN,
            maxRatingsPerDay: 10,
            minReputationToRate: 100,
            requireMinReputation: true
        });
    }
}
