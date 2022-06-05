const { expect } = require("chai");
const { ethers } = require("hardhat");


const name = "Token";
const symbol = "TKN";
const initialSupply = 1000;

var BigNumber = require('big-number');

const digits = "000000000000000000"


describe("Token Testing", function () {

  console.log("start testing")

  let Token, token, owner, addr1, addr2;

  const increaseTime = async (days) => {
    await ethers.provider.send('evm_increaseTime', [days * 24 * 60 * 60]);
    await ethers.provider.send('evm_mine');
  };

  const currentTime = async () => {
    const blockNum = await ethers.provider.getBlockNumber();
    const block = await ethers.provider.getBlock(blockNum);
    return block.timestamp;
  }

  beforeEach(async () => {
    Token = await ethers.getContractFactory("RewardSharks");
    token = await Token.deploy();
    await token.deployed();
    [owner, addr1, addr2, addr3, _] = await ethers.getSigners();
  })

  describe("Initial Deploy", async () => {

    it('Should set the right name', async () => {
      expect(await token.name()).to.equal(name);
    });

    it("Should set right symbol", async () => {
      expect(await token.symbol()).to.equal(symbol);
    });

    it("Should set right owner balance", async () => {
      expect(await token.balanceOf(owner.address)).to.equal((initialSupply));
    });

    it("Should set right decimals", async () => {
      expect(await token.decimals()).to.equal(18);
    })

    it("Should set the right owner", async () => {
      expect(await token.owner()).to.equal(owner.address);
    })

    it("Should set right Owner free tokens", async () => {
      expect(await token.getFreeTokens(owner.address)).to.equal(initialSupply);
    })

    it("should set the right owner free balance", async () => {
      expect(await token.getFreeTokens(owner.address)).to.equal(await token.balanceOf(owner.address));
    })
  });
});


// ****************************************************************
