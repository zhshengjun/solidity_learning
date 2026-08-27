// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Proposal {
    string name; // 提案名称
    address[] voters; // 投票人列表
    mapping(address => uint) voterIndexs; // 投票人索引
}

contract VoterContract {
    Proposal[] proposals; // 提案列表
    mapping(string => uint) proposalIndexs; // 提案索引
    mapping(string => bool) proposalExist; // 提案是否存在

    // 投票数量
    mapping(address => uint8) public voters; // 每个人的票数
    mapping(address => mapping(string => bool)) public voted; // 已经投票的数据

    function addProposal(string calldata proposalName) public {
        require(!proposalExist[proposalName], "has existed proposalName");
        // 这里 Proposal 有 storage 类型的,需要特殊处理,不能直接 new
        Proposal storage proposal = proposals.push();
        proposal.name = proposalName;
        proposalIndexs[proposalName] = proposals.length - 1;
    }

    function vote(string calldata proposalName) public {
        require(proposalExist[proposalName], "not existed proposalName");

        require(voters[msg.sender] > 0, "not enough voter");
        require(!voted[msg.sender][proposalName], "has voted");

        voted[msg.sender][proposalName] = true; // 投票
        voters[msg.sender] -= 1; // 扣出票数
        Proposal storage proposal = proposals[proposalIndexs[proposalName]];
        proposal.voterIndexs[msg.sender] = proposal.voters.length - 1;
        proposal.voters.push(msg.sender);
    }

    function cancel(string calldata proposalName) public {
        require(proposalExist[proposalName], "not existed proposalName");
        require(voted[msg.sender][proposalName], "not voted");

        voted[msg.sender][proposalName] = false; // 取消投票
        voters[msg.sender] += 1; // 加票数

        // 维护投票数据
        Proposal storage proposal = proposals[proposalIndexs[proposalName]];
        uint proposalVoterLength = proposal.voters.length;

        // 如果只有最后一个人投票了
        if (proposalVoterLength > 1) {
            // 当前操作人的列表索引
            uint index = proposal.voterIndexs[msg.sender];

            // 把最后一个人交换下位置
            proposal.voters[index] = proposal.voters[proposalVoterLength - 1];
            proposal.voterIndexs[
                proposal.voters[proposalVoterLength - 1]
            ] = index;
        }
        // 清理最后一个数据
        proposal.voters.pop();
        delete proposal.voterIndexs[msg.sender];
    }

    function winProposal() public view returns (string memory) {
        uint256 proposalLength = proposals.length;
        require(proposalLength > 0, "no proposals");
        string memory winName = proposals[0].name;
        uint256 maxVoter = proposals[0].voters.length;

        for (uint256 i = 1; i < proposalLength; i++) {
            uint256 voterNumber = proposals[i].voters.length;
            if (voterNumber > maxVoter) {
                maxVoter = voterNumber;
                winName = proposals[i].name;
            }
        }
        return winName;
    }
    
}
