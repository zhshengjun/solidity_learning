// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract Voting {
    mapping(string => uint256) votes;
    string[] candidates;

    function addCandicate(string calldata candidate) external {
        // 这里需要校验，是否重复了
        candidates.push(candidate);
        votes[candidate] = 0;
    }

    function vote(string calldata candidate) external {
        votes[candidate] += 1;
    }

    function getVotes(
        string calldata candidate
    ) external view returns (uint256) {
        return votes[candidate];
    }

    function resetVotes() external {
        uint256 length = candidates.length;
        for (uint256 index; index < length; index++) {
            votes[candidates[index]] = 0;
        }
    }
}
