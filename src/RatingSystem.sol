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

contract RatingSystem {}
