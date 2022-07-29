const SimpleAuction = artifacts.require("SimpleAuction");
const { utils } = require("web3");
const truffleAssert = require("truffle-assertions");

contract("SimpleAuction", (accts) => {
  let auction;
  let beneficiary = accts[0];
  let auctionEndTime = utils.toBN(10);
  // 86400
  let blockTimeStamp;

  before(async () => {
    blockTimeStamp = Math.round(new Date().getTime() / 1000);
    auction = await SimpleAuction.new(auctionEndTime, beneficiary.toString());
  });

  it("Should have beneficiary", async () => {
    const result = (await auction.beneficiary.call()).toString();
    assert.isDefined(result);
    assert.equal(result, beneficiary);
  });

  it("Should have auctionEndTime", async () => {
    const result = (await auction.auctionEndTime.call()).toNumber();
    const expected = blockTimeStamp + auctionEndTime.toNumber();
    assert.isDefined(result);
    assert.closeTo(result, expected, 3);
  });

  it("Should have highestBidder", async () => {
    const result = (await auction.highestBidder()).toString();
    const expected = "0x0000000000000000000000000000000000000000";
    assert.isDefined(result);
    assert.equal(result, expected);
  });

  it("Should have highestBid", async () => {
    const result = (await auction.highestBid()).toNumber();
    const expected = utils.toBN(0);
    assert.isDefined(result);
    assert.isNumber(result);
    assert.equal(result, expected);
  });

  it("Should be able to bid", async () => {
    const res1 = await auction.bid({ value: 1, from: accts[1] });
    truffleAssert.eventEmitted(res1, "HighestBidIncreased");
    const highestBid1 = (await auction.highestBid()).toNumber();
    assert.equal(highestBid1, 1);

    const res2 = await auction.bid({ value: 2, from: accts[2] });
    truffleAssert.eventEmitted(res2, "HighestBidIncreased");
    const highestBid2 = (await auction.highestBid()).toNumber();
    assert.equal(highestBid2, 2);
  });

  it("Should be able to withdraw bid", async () => {
    const result = await auction.withdraw({ from: accts[1] });
    assert.isDefined(result);
    assert.isTrue(result.receipt.status);
  });

  it("Should not be able to end auction before end time", async () => {
    await truffleAssert.reverts(auction.endAuction());
    await new Promise((resolve) => setTimeout(resolve, 20000));

    truffleAssert.eventEmitted(await auction.endAuction(), "AuctionEnded");
    // await truffleAssert.reverts(auction.endAuction());
  });
});
