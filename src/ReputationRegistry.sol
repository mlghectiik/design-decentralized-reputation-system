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
    bool public decayEnabled = true;

    // Events
    event UserRegistered(address indexed user, uint256 initialReputation);
    event ReputationUpdated(
        address indexed user, 
        uint256 oldScore, 
        uint256 newScore, 
        address indexed rater
    );
    event ReputationDecayed(address indexed user, uint256 oldScore, uint256 newScore);
    event AuthorizedRaterAdded(address indexed rater);
    event AuthorizedRaterRemoved(address indexed rater);
    event ReputationParametersUpdated(
        uint256 minRaterReputation,
        uint256 maxWeightMultiplier
    );

    // Errors
    error UserNotRegistered(address user);
    error UserAlreadyRegistered(address user);
    error InvalidReputationScore(uint256 score);
    error UnauthorizedRater(address rater);
    error InvalidParameters();
    error SelfRatingNotAllowed();

    constructor(address _owner) Ownable(_owner) {}

    /**
     * @dev Register a new user in the reputation system
     * @param user Address of the user to register
     */
    function registerUser(address user) external onlyOwner {
        if (_reputations[user].isRegistered) {
            revert UserAlreadyRegistered(user);
        }
        
        _reputations[user] = ReputationData({
            score: INITIAL_REPUTATION,
            totalRatings: 0,
            totalScore: 0,
            lastUpdateTime: block.timestamp,
            lastDecayTime: block.timestamp,
            isRegistered: true
        });
        
        _registeredUsers.push(user);
        
        emit UserRegistered(user, INITIAL_REPUTATION);
    }

    /**
     * @dev Update a user's reputation based on a new rating
     * @param user Address of the user being rated
     * @param rating New rating score (0-1000)
     * @param rater Address of the user giving the rating
     */
    function updateReputation(
        address user,
        uint256 rating,
        address rater
    ) external nonReentrant {
        if (!authorizedRaters[msg.sender]) {
            revert UnauthorizedRater(msg.sender);
        }
        
        if (!_reputations[user].isRegistered) {
            revert UserNotRegistered(user);
        }
        
        if (!_reputations[rater].isRegistered) {
            revert UserNotRegistered(rater);
        }
        
        if (user == rater) {
            revert SelfRatingNotAllowed();
        }
        
        if (rating > MAX_REPUTATION) {
            revert InvalidReputationScore(rating);
        }
        
        // Apply decay before updating
        _applyDecay(user);
        
        ReputationData storage userData = _reputations[user];
        uint256 oldScore = userData.score;
        
        // Calculate weighted rating based on rater's reputation
        uint256 weightedRating = _calculateWeightedRating(rating, rater);
        
        // Update reputation using weighted average
        userData.totalRatings += 1;
        userData.totalScore += weightedRating;
        userData.score = userData.totalScore / userData.totalRatings;
        userData.lastUpdateTime = block.timestamp;
        
        // Ensure score stays within bounds
        if (userData.score > MAX_REPUTATION) {
            userData.score = MAX_REPUTATION;
        }
        
        emit ReputationUpdated(user, oldScore, userData.score, rater);
    }

    /**
     * @dev Get a user's current reputation score
     * @param user Address of the user
     * @return Current reputation score
     */
    function getReputation(address user) external view returns (uint256) {
        if (!_reputations[user].isRegistered) {
            revert UserNotRegistered(user);
        }
        
        // Calculate decay without applying it (view function)
        return _calculateDecayedReputation(user);
    }

    /**
     * @dev Get detailed reputation data for a user
     * @param user Address of the user
     * @return ReputationData struct with all reputation information
     */
    function getReputationData(address user) external view returns (ReputationData memory) {
        if (!_reputations[user].isRegistered) {
            revert UserNotRegistered(user);
        }
        
        ReputationData memory data = _reputations[user];
        data.score = _calculateDecayedReputation(user);
        return data;
    }

    function getRegisteredUsers(
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory users) {
        uint256 total = _registeredUsers.length;
        
        if (offset >= total) {
            return new address[](0);
        }
        
        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }
        
        users = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            users[i - offset] = _registeredUsers[i];
        }
    }
}
