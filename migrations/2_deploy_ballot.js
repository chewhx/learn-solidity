const Ballot = artifacts.require("Ballot");

module.exports = function (deployer) {
  deployer.deploy(Ballot, [
    "0x4d69636861656c204a61636b736f6e277320546872696c6c6572",
    "0x4c6f76696e672056696e63656e74",
    "0x4e6f626f6479",
    "0x5468726565204d656e20616e642061204c6567",
    "0x546865205468697264204d616e",
  ]);
};

//[ "Michael Jackson's Thriller", 'Loving Vincent', 'Nobody', 'Three Men and a Leg', 'The Third Man' ]
