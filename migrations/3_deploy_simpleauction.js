const SimpleAuction = artifacts.require("SimpleAuction");
const { utils } = require("web3");

module.exports = function (deployer) {
  deployer.deploy(
    SimpleAuction,
    utils.toBN(86400000),
    "0xb2a244d265f795c1311cfa85ca9fff9f3d3b1ee8"
  );
};
