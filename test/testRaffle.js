const fs = require('fs');
const truffleContract = require('@truffle/contract');
const { expect } = require("chai");
const { ethers, contract } = require("hardhat");

const CONFIG = require("../credentials");
const { it } = require('mocha');
const provider = new Web3.providers.HttpProvider("http://127.0.0.1:8545");

describe("Reward Test Cases", () => {

    before(async () => {
    
    const ContractToken = await ethers.getContractFactory("AlphaSharkToken");
    contractToken = await ContractToken.deploy("ALS", "ALS S", 1000000);
    await contractToken.deployed();

    const ContractRaffle = await ethers.getContractFactory("RaffleSharks");
    contractRaffle = await ContractRaffle.deploy(contractToken.address);
    await contractRaffle.deployed();

    accounts = await ethers.getSigners();

    })

    it("Should be able to deploy Token Contract", async () => {
        // expect(await nft.owner()).to.equal(accounts[0].address);
        console.log("Initial Token Balance ", await contractToken.balanceOf(accounts[0].address));
        //expect(await nft.checkFixedBooster(1)).to.equal("100");
        // console.log("TOKEN ADDRESS: ", token.address);
        // console.log("Total Supply: ",await token.totalSupply());
        
        // console.log("Staking Address: ", reward.address);
        // expect(await reward.owner()).to.equal(accounts[0].address);

        // await nft.togglePauseState();
        // await nft.togglePublicSale();

        // await nft.addWhiteListAddress([accounts[1].address, accounts[2].address, accounts[3].address, accounts[4].address]);

        // await nft.connect(accounts[1]).publicSaleMint(4, {value: ethers.utils.parseEther("0.8")});
        // await nft.connect(accounts[5]).publicSaleMint(4, {value: ethers.utils.parseEther("0.8")});
        // await nft.connect(accounts[2]).publicSaleMint(2, {value: ethers.utils.parseEther("0.4")});
        // await nft.connect(accounts[6]).publicSaleMint(2, {value: ethers.utils.parseEther("0.4")});

        //await reward.initialize(reward.address, nft.address, 78)
    })

    it("Should be able to deploy raffle contract", async() => {
        expect(await contractRaffle.owner()).to.equal(accounts[0].address);
    })

    it("Transfer tokens", async() => {
        await contractToken.connect(accounts[0]).transfer(accounts[1].address, "50000000000000000000000");
        await contractToken.connect(accounts[1]).approve(contractRaffle.address, "50000000000000000000000");
        await contractToken.connect(accounts[0]).transfer(accounts[2].address, "60000000000000000000000");
        await contractToken.connect(accounts[2]).approve(contractRaffle.address, "60000000000000000000000");
        await contractToken.connect(accounts[0]).transfer(accounts[3].address, "70000000000000000000000");
        await contractToken.connect(accounts[3]).approve(contractRaffle.address, "70000000000000000000000");
        await contractToken.connect(accounts[0]).transfer(accounts[4].address, "80000000000000000000000");
        await contractToken.connect(accounts[4]).approve(contractRaffle.address, "80000000000000000000000");
        await contractToken.connect(accounts[0]).transfer(accounts[5].address, "90000000000000000000000");
        await contractToken.connect(accounts[5]).approve(contractRaffle.address, "90000000000000000000000");
        await contractToken.connect(accounts[0]).transfer(accounts[6].address, "100000000000000000000000");
        await contractToken.connect(accounts[6]).approve(contractRaffle.address, "100000000000000000000000");
        await contractToken.connect(accounts[0]).transfer(accounts[7].address, "11000000000000000000000");
        await contractToken.connect(accounts[0]).transfer(accounts[8].address, "12000000000000000000000");
        await contractToken.connect(accounts[0]).transfer(accounts[9].address, "13000000000000000000000");
    })

    it("Buy Raffles", async() => {
        console.log(await contractRaffle.isRaffleActive(1));
        await contractRaffle.connect(accounts[0]).toggleRaffleStatus(1);
        console.log(await contractRaffle.isRaffleActive(1));

        await contractRaffle.connect(accounts[1]).buyRaffleTicket(1, 500);

        console.log(await contractRaffle.totalRaffleTicket(1));
        // console.log(await contractRaffle.getRaffleAddressList(1,0));
        console.log(await contractRaffle.getRaffleTokens(accounts[1].address,1));

        await contractRaffle.connect(accounts[2]).buyRaffleTicket(1, 300);
        
        console.log(await contractRaffle.totalRaffleTicket(1));
        // console.log(await contractRaffle.getRaffleAddressList(1,1));
        console.log(await contractRaffle.getRaffleTokens(accounts[2].address,1));

        await contractRaffle.connect(accounts[2]).buyRaffleTicket(1, 300);
        
        console.log(await contractRaffle.totalRaffleTicket(1));
        // console.log(await contractRaffle.getRaffleAddressList(1,1));
        console.log(await contractRaffle.getRaffleTokens(accounts[2].address,1));

        await contractRaffle.connect(accounts[3]).buyRaffleTicket(1, 700);
        
        console.log(await contractRaffle.totalRaffleTicket(1));
        // console.log(await contractRaffle.getRaffleAddressList(1,2));
        console.log(await contractRaffle.getRaffleTokens(accounts[3].address,1));

        console.log("Raffle Completed Status: ",await contractRaffle.isRaffleCompleted(1));
        await contractRaffle.connect(accounts[0]).toggleRaffleStatus(1);

        await contractRaffle.connect(accounts[0]).generateRaffleWinner(1);

        console.log("Winner ", await contractRaffle.raffleIdWinner(1));
        console.log("Raffle Completed Status: ",await contractRaffle.isRaffleCompleted(1));
    })

    it("Refund Tokens", async() => {
        var list = await contractRaffle.getRaffleAddressList(1);
        var winner = await contractRaffle.raffleIdWinner(1);
        for(var i=0;i<list.length;i++){
            if(list[i]!=winner){
                console.log("Pre Refund Balance of " + list[i] + " is: " + await contractToken.balanceOf(list[i]));
                await contractRaffle.connect(accounts[i+1]).refundTokens(1);
                console.log("Post Refund Balance of " + list[i] + " is: " + await contractToken.balanceOf(list[i]));
            }
        }
    })

    it("Buy Raffles 2", async() => {
        console.log(await contractRaffle.isRaffleActive(2));
        await contractRaffle.connect(accounts[0]).toggleRaffleStatus(2);
        console.log(await contractRaffle.isRaffleActive(2));

        await contractRaffle.connect(accounts[4]).buyRaffleTicket(2, 500);

        console.log("Total Raffle Tickets: ", await contractRaffle.totalRaffleTicket(2));
        // console.log(await contractRaffle.getRaffleAddressList(1,0));
        console.log("Raffle 2 Tickets account 4: ", await contractRaffle.getRaffleTokens(accounts[4].address,1));

        await contractRaffle.connect(accounts[5]).buyRaffleTicket(2, 300);
        
        console.log("Total Raffle Tickets: ", await contractRaffle.totalRaffleTicket(2));
        // console.log(await contractRaffle.getRaffleAddressList(1,1));
        console.log("Raffle 2 Tickets account 5: ", await contractRaffle.getRaffleTokens(accounts[5].address,2));

        await contractRaffle.connect(accounts[5]).buyRaffleTicket(2, 300);
        
        console.log("Total Raffle Tickets: ", await contractRaffle.totalRaffleTicket(2));
        // console.log(await contractRaffle.getRaffleAddressList(1,1));
        console.log("Raffle 2 Tickets account 5: ", await contractRaffle.getRaffleTokens(accounts[5].address,2));

        await contractRaffle.connect(accounts[6]).buyRaffleTicket(2, 700);
        
        console.log("Total Raffle Tickets: ", await contractRaffle.totalRaffleTicket(2));
        // console.log(await contractRaffle.getRaffleAddressList(1,2));
        console.log("Raffle 2 Tickets account 6: ", await contractRaffle.getRaffleTokens(accounts[6].address,2));

        console.log("Raffle Completed Status: ",await contractRaffle.isRaffleCompleted(2));
        await contractRaffle.connect(accounts[0]).toggleRaffleStatus(2);

        await contractRaffle.connect(accounts[0]).generateRaffleWinner(2);

        console.log("Winner Raffle 2: ", await contractRaffle.raffleIdWinner(2));
        console.log("Raffle 2 Completed Status: ",await contractRaffle.isRaffleCompleted(2));
    })

    it("Pre & Post Refund Tokens", async() => {
        var list = await contractRaffle.getRaffleAddressList(2);
        var winner = await contractRaffle.raffleIdWinner(2);
        console.log("Winner Raffle 2: " + winner);
        for(var i=0;i<list.length;i++){
            console.log("Pre Refund Balance of " + list[i] + " is: " + await contractToken.balanceOf(list[i]));
        }

        await contractRaffle.connect(accounts[0]).refundAllRaffleTokens(2);

        var list = await contractRaffle.getRaffleAddressList(2);
        for(var i=0;i<list.length;i++){
            console.log("Post Refund Balance of " + list[i] + " is: " + await contractToken.balanceOf(list[i]));
        }
    })

    it("Withdraw ", async() => {
        console.log("Pre Withdraw Balance: ", await contractToken.balanceOf(accounts[0].address));
        await contractRaffle.connect(accounts[0]).emergencyWithdrawTokens();
        console.log("Post Withdraw Balance: ",await contractToken.balanceOf(accounts[0].address));

    })

    it("Buy Raffles Multiple", async() => {
        await contractRaffle.connect(accounts[0]).toggleRaffleStatus(5);
        await contractRaffle.connect(accounts[0]).toggleRaffleStatus(6);
        await contractRaffle.connect(accounts[0]).toggleRaffleStatus(7);

        await contractRaffle.connect(accounts[1]).buyRaffleTicket(5, 1500);
        await contractRaffle.connect(accounts[1]).buyRaffleTicket(6, 2000);
        await contractRaffle.connect(accounts[1]).buyRaffleTicket(7, 2500);

        console.log("Total Raffle Tickets 5: ",await contractRaffle.totalRaffleTicket(5));
        console.log("Total Raffle Tickets 6: ",await contractRaffle.totalRaffleTicket(6));
        console.log("Total Raffle Tickets 7: ",await contractRaffle.totalRaffleTicket(7));

        await contractRaffle.connect(accounts[2]).buyRaffleTicket(5, 1200);
        await contractRaffle.connect(accounts[2]).buyRaffleTicket(6, 2200);
        await contractRaffle.connect(accounts[2]).buyRaffleTicket(7, 2700);

        console.log("Total Raffle Tickets 5: ",await contractRaffle.totalRaffleTicket(5));
        console.log("Total Raffle Tickets 6: ",await contractRaffle.totalRaffleTicket(6));
        console.log("Total Raffle Tickets 7: ",await contractRaffle.totalRaffleTicket(7));

        await contractRaffle.connect(accounts[3]).buyRaffleTicket(5, 1300);
        await contractRaffle.connect(accounts[3]).buyRaffleTicket(6, 2300);
        await contractRaffle.connect(accounts[3]).buyRaffleTicket(7, 2800);

        console.log("Total Raffle Tickets 5: ",await contractRaffle.totalRaffleTicket(5));
        console.log("Total Raffle Tickets 6: ",await contractRaffle.totalRaffleTicket(6));
        console.log("Total Raffle Tickets 7: ",await contractRaffle.totalRaffleTicket(7));

        await contractRaffle.connect(accounts[4]).buyRaffleTicket(5, 2300);
        await contractRaffle.connect(accounts[4]).buyRaffleTicket(6, 1300);
        await contractRaffle.connect(accounts[4]).buyRaffleTicket(7, 800);

        console.log("Total Raffle Tickets 5: ",await contractRaffle.totalRaffleTicket(5));
        console.log("Total Raffle Tickets 6: ",await contractRaffle.totalRaffleTicket(6));
        console.log("Total Raffle Tickets 7: ",await contractRaffle.totalRaffleTicket(7));

        console.log("Raffle Status 5: ", await contractRaffle.isRaffleActive(5));
        console.log("Raffle Status 6: ", await contractRaffle.isRaffleActive(6));
        console.log("Raffle Status 7: ", await contractRaffle.isRaffleActive(7));

        await contractRaffle.connect(accounts[0]).generateRaffleWinner(5);
        console.log("Winner Raffle 5 ", await contractRaffle.raffleIdWinner(5));
        console.log("Raffle Completed Status 5: ",await contractRaffle.isRaffleCompleted(5));

        await contractRaffle.connect(accounts[0]).generateRaffleWinner(6);
        console.log("Winner Raffle 6: ", await contractRaffle.raffleIdWinner(6));
        console.log("Raffle Completed Status 6: ",await contractRaffle.isRaffleCompleted(6));

        await contractRaffle.connect(accounts[0]).generateRaffleWinner(7);
        console.log("Winner Raffle 7: ", await contractRaffle.raffleIdWinner(7));
        console.log("Raffle Completed Status 7: ",await contractRaffle.isRaffleCompleted(7));

        console.log("Raffle Status 5: ", await contractRaffle.isRaffleActive(5));
        console.log("Raffle Status 6: ", await contractRaffle.isRaffleActive(6));
        console.log("Raffle Status 7: ", await contractRaffle.isRaffleActive(7));
    })

})