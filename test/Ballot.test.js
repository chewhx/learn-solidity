const Ballot = artifacts.require("Ballot");
const { utils } = require("web3");
const truffleAssert = require("truffle-assertions");

const REVERT_PREFIX =
  "Error: Returned error: VM Exception while processing transaction: revert ";

contract("Ballot", (accts) => {
  let ballot;
  let sender = accts[0];

  before(async () => {
    ballot = await Ballot.deployed();
  });

  it("Should read chairperson", async () => {
    const chairperson = await ballot.chairperson.call();
    assert(chairperson === sender);
  });

  it("Should have proposals", async () => {
    const proposal = await ballot.proposals.call(0);
    assert(
      proposal.name ===
        "0x4d69636861656c204a61636b736f6e277320546872696c6c6572000000000000"
    );
  });

  describe("Should be able to give right to vote", () => {
    before(async () => {
      try {
        await ballot.giveRightToVote(accts[1], { from: accts[0] });
        await ballot.giveRightToVote(accts[2], { from: accts[0] });
        await ballot.giveRightToVote(accts[3], { from: accts[0] });
      } catch (err) {
        console.error(err);
      }
    });

    it("Should have voters", async () => {
      const voter1 = await ballot.voters.call(accts[1]);
      const voter2 = await ballot.voters.call(accts[2]);
      const voter3 = await ballot.voters.call(accts[3]);

      assert.isDefined(voter1);
      assert(voter1.weight.toNumber() === 1);
      assert(!voter1.hasVoted);

      assert.isDefined(voter2);
      assert(voter2.weight.toNumber() === 1);
      assert(!voter2.hasVoted);

      assert.isDefined(voter3);
      assert(voter3.weight.toNumber() === 1);
      assert(!voter3.hasVoted);
    });
  });

  describe("Should be able to delegate", () => {
    before(async () => {
      await ballot.delegate(accts[2], { from: accts[1] });
    });

    it("Should voter 1 delegate to voter 2", async () => {
      const voter1 = await ballot.voters.call(accts[1]);
      const voter2 = await ballot.voters.call(accts[2]);

      assert.isDefined(voter1);
      assert(voter1.weight.toNumber() === 1);
      assert(voter1.hasVoted);
      assert(voter1.delegate === accts[2]);

      assert.isDefined(voter2);
      assert(voter2.weight.toNumber() === 2);
      assert(!voter2.hasVoted);
    });
  });

  describe("Should be able to vote", () => {
    it("Should throw error because voter1 has delegated", async () => {
      await truffleAssert.reverts(
        ballot.vote.call(utils.toBN(0), { from: accts[1] })
        // REVERT_PREFIX + "Has already voted"
      );
    });

    it("Should voted for proposal[0], by voter 2", async () => {
      const proposalIdx = 0;

      await ballot.vote(utils.toBN(proposalIdx), { from: accts[2] });

      const votedProposal = await ballot.proposals.call(proposalIdx);

      assert(votedProposal.voteCount.toNumber() === 2);
    });

    it("Should voted for proposal[1], by voter 3", async () => {
      const proposalIdx = 1;

      await ballot.vote(utils.toBN(proposalIdx), { from: accts[3] });

      const votedProposal = await ballot.proposals.call(proposalIdx);

      assert(votedProposal.voteCount.toNumber() === 1);
    });
  });

  describe("Should have winning proposal", () => {
    it("Should have proposal[0] winning", async () => {
      const winningProposal = await ballot.winningProposal();
      assert.equal(winningProposal.toNumber(), 0);
    });

    it("Should have proposal[0] name winning", async () => {
      const winningProposal = await ballot.winnerName();
      const name = utils.hexToString(winningProposal);
      assert.equal(name, "Michael Jackson's Thriller");
    });
  });
});
