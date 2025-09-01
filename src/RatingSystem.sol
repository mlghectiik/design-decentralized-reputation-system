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
}
