// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

contract Ballot {
    /* =======================================
        STRUCTS
    =========================================== */
    struct Voter {
        uint256 weight; // weight accumulate by delegation
        bool hasVoted;
        address delegate; // person delegated to
        uint256 votedProposalIndex; // index of the voted proposal
    }

    struct Proposal {
        bytes32 name;
        uint256 voteCount;
    }

    /* =======================================
        MODIFIERS
    =========================================== */

    // Require sender has right to vote
    modifier hasRightToVote(address voter) {
        require(voters[voter].weight != 0, "Has no right to vote");
        _;
    }

    // Require sender has not voted
    modifier hasNotVoted(address voter) {
        require(!voters[voter].hasVoted, "Has already voted");
        _;
    }
    /* =======================================
        VARIABLES
    =========================================== */

    address public chairperson;
    Proposal[] public proposals;
    mapping(address => Voter) public voters;

    constructor(bytes32[] memory proposalNames) {
        // Set msg.sender as chairperson and assign voting weight 1
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // Loop through proposal names and add to proposals
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    /* =======================================
        FUNCTIONS
    =========================================== */

    /**-----------------------------------------
    @dev Give listed voter right to vote, by assigning weight of 1.
    @param voter Address of voter 
    --------------------------------------------*/
    function giveRightToVote(address voter) external {
        // Require chairperson to be sender
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote"
        );
        // Require voter to not have already voted
        require(!voters[voter].hasVoted, "The voter has voted");
        // Require voter to have no weight
        require(voters[voter].weight == 0);
        // Assign voter weight
        voters[voter].weight = 1;
    }

    /**-----------------------------------------
    @dev Delegate one's vote to another.
    @param to Address of delegated voter
    --------------------------------------------*/
    function delegate(address to)
        external
        hasRightToVote(msg.sender)
        hasNotVoted(msg.sender)
    {
        Voter storage sender = voters[msg.sender];

        // Require sender to not delegate to self
        require(to != msg.sender, "You may not delegate to yourself");

        Voter storage _delegate = voters[to];

        // Forward the delegation, if 'to' also delegated
        while (_delegate.delegate != address(0)) {
            require(_delegate.delegate != msg.sender);
            _delegate = voters[_delegate.delegate];
        }

        // Require _delegate to have voting rights
        require(_delegate.weight >= 1);

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender]`
        sender.hasVoted = true;
        sender.delegate = to;

        if (_delegate.hasVoted) {
            // If the delegate already voted, directly add to the number of votes
            proposals[_delegate.votedProposalIndex].voteCount += sender.weight;
        } else {
            //  If the delegate did not vote yet, add to her weight.
            _delegate.weight += sender.weight;
        }
    }

    /**-----------------------------------------
    @dev Vote on a propsal.
    @param proposalIndex Index of the proposal to be voted upon 
    --------------------------------------------*/
    function vote(uint256 proposalIndex)
        external
        hasRightToVote(msg.sender)
        hasNotVoted(msg.sender)
    {
        Voter storage sender = voters[msg.sender];
        sender.hasVoted = true;
        sender.votedProposalIndex = proposalIndex;

        // If `proposal` is out of the range of the array, this will throw automatically and revert all changes.
        proposals[proposalIndex].voteCount += sender.weight;
    }

    /**-----------------------------------------
    @dev View winning proposal
    @return uint256  Index of winning proposal
    --------------------------------------------*/
    function winningProposal() public view returns (uint256) {
        // Declare winning proposal index
        uint256 _winningProposal;
        // Declare winning proposal count to keep track
        uint256 _winningVoteCount = 0;

        // Iterate through all the proposals
        for (uint256 i = 0; i < proposals.length; i++) {
            // If the proposal vote count exceeds the current winning count,
            if (proposals[i].voteCount > _winningVoteCount) {
                // Assign new winning count
                _winningVoteCount = proposals[i].voteCount;
                // Assign new winning proposal to current proposal
                _winningProposal = i;
            }
        }

        return _winningProposal;
    }

    /**-----------------------------------------
    @dev Return the winning proposal name
    @return bytes32  Name of winning proposal
    --------------------------------------------*/
    function winnerName() external view returns (bytes32) {
        // proposalsArray [winningProposalIndex] (dot) name
        return proposals[winningProposal()].name;
    }
}
