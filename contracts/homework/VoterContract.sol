// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Proposal {
    string name; // 提案名称
    address[] voters; // 投票人列表
    mapping(address => uint) voterIndexs; // 投票人索引
}

contract VoterContract {
    address internal immutable owner;
    Proposal[] internal proposals; // 提案列表
    mapping(string => uint256) internal proposalIndexs; // 提案索引

    // 投票数量
    mapping(address => uint256) internal voteNumbers; // 每个人的票数
    mapping(address => mapping(uint256 => bool)) internal voted; // 个人已经投票的数据

    constructor() {
        owner = msg.sender;
    }

    function addProposal(string calldata proposalName) public {
        require(msg.sender == owner, "not owner");
        require(proposalIndexs[proposalName] == 0, "has existed proposalName");

        // 这里 Proposal 有 storage 类型的,需要特殊处理,不能直接 new
        Proposal storage proposal = proposals.push();
        proposal.name = proposalName;
        proposalIndexs[proposalName] = proposals.length;
    }

    function addVoteNumber(address addr, uint256 number) public {
        require(msg.sender == owner, "not owner");
        voteNumbers[addr] += number;
    }

    function vote(uint256 proposalId) public {
        require(proposalId < proposals.length, "not existed proposalName");

        Proposal storage proposal = proposals[proposalId];

        require(voteNumbers[msg.sender] > 0, "not enough voter");
        require(!voted[msg.sender][proposalId], "has voted");

        voted[msg.sender][proposalId] = true; // 投票
        voteNumbers[msg.sender] -= 1; // 扣出票数

        proposal.voters.push(msg.sender);
        proposal.voterIndexs[msg.sender] = proposal.voters.length - 1;
    }

    function cancel(uint256 proposalId) public {
        require(proposalId < proposals.length, "not existed proposalName");

        Proposal storage proposal = proposals[proposalId];
        require(voted[msg.sender][proposalId], "not voted");

        voted[msg.sender][proposalId] = false; // 取消投票
        voteNumbers[msg.sender] += 1; // 加票数

        // 维护投票数据
        uint256 last = proposal.voters.length - 1;
        // 当前操作人的列表索引
        uint256 index = proposal.voterIndexs[msg.sender];

        // 如果只有最后一个人投票了
        if (index != last) {
            // 把最后一个人换到需要删除的 index 上
            proposal.voters[index] = proposal.voters[last];
            proposal.voterIndexs[proposal.voters[last]] = index;
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
