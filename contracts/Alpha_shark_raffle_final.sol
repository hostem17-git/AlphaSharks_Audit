// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IAlphaSharkRewards {
    function updateAddLockTokens(uint256 _amount, address _address, bool _add) external;
    function availableTokens(address _address) external view returns (uint256);
}

contract RaffleSharks is Ownable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public ALPHA_SHARK_FACTORY;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct tokenOwner {
        address owner;
        mapping(uint256 => uint256) ticketForRaffle; // Raffle Id ==> Tickets
    }

    address public AlphaSharkRewards;

    // Rewards Claims
    bool public refundAllowed = true;

    uint256 public multiplier = 100;

    struct Raffle {
        uint256 raffleId;
        bool active;
        bool completed;
        address[] raffleIdWinner;
        address[] raffleContenders;
        uint256 totalRaffleTicket;
        uint256 startTime;
        uint256 endTime;
    }

    struct User {
        address owner;
        uint256 raffleId;
        uint256 rafflePurchased;
    }

    mapping(uint256 => Raffle) public getRaffleDetails;
    mapping(address => User[]) public userRaffleDetails;

    // get Owner Tokens
    mapping(address => tokenOwner) public getOwner;

    uint256[] public activeRaffleList;
    uint256[] public completedRaffleList;
    address[] public winnerList;

    constructor(address _rewardsContractAddress) ReentrancyGuard() {
        AlphaSharkRewards = _rewardsContractAddress;
        ALPHA_SHARK_FACTORY = msg.sender;
        transferOwnership(msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function updateRewardContractAddress(address _rewardsContractAddress) external onlyOwner {
        AlphaSharkRewards = _rewardsContractAddress;
    }

    function activateRaffle(uint256 _raffleId) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
        Raffle storage _raffle = getRaffleDetails[_raffleId];
        require(!_raffle.completed, "Raffle has been completed Already");
        require(!_raffle.active, "Raffle has already started");
        activeRaffleList.push(_raffleId);
        _raffle.raffleId = _raffleId;
        _raffle.active = true;
        _raffle.startTime = block.timestamp;
    }

    function raffleCounter(uint256 _tokenAmount) internal view returns (uint256) {
         require(_tokenAmount%multiplier==0, "Amount Should be multiple of Multiplier");
         return _tokenAmount.div(multiplier);
    }

    function getRaffleTokens(address _address, uint256 _raffleId) public view returns (uint256) {
        return getOwner[_address].ticketForRaffle[_raffleId];
    }

    function getRaffleAddressList(uint256 _raffleId) public view returns (address[] memory) {
        return getRaffleDetails[_raffleId].raffleContenders;
    }

    function buyRaffleTicket(uint256 _raffleId, uint256 _amount) external {
        Raffle storage _raffle = getRaffleDetails[_raffleId];
        require(_amount > 0, "Need to pass more tokens");
        require(IAlphaSharkRewards(AlphaSharkRewards).availableTokens(msg.sender) >= _amount.mul(10**18), "Insufficient Balance");
        require(_raffle.active, "Raffle is Inactive");
        require(!_raffle.completed, "Raffle completed");
        
        uint256 tokenPurchase = raffleCounter(_amount);
        
        tokenOwner storage _tokenOwner = getOwner[msg.sender];
        _tokenOwner.owner = msg.sender;
        
        if(_tokenOwner.ticketForRaffle[_raffleId]==0)
        {
            _raffle.raffleContenders.push(msg.sender);
        }
        
        _tokenOwner.ticketForRaffle[_raffleId] += tokenPurchase;
        _raffle.totalRaffleTicket += tokenPurchase;

        IAlphaSharkRewards(AlphaSharkRewards).updateAddLockTokens(_amount.mul(10**18), msg.sender, true);
        User memory user;
        user.owner = msg.sender;
        user.raffleId = _raffleId;
        user.rafflePurchased = tokenPurchase;
        userRaffleDetails[msg.sender].push(user);
    }

    function refundAllRaffleTokens(uint256 _raffleId) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
        Raffle storage _raffle = getRaffleDetails[_raffleId];
        require(refundAllowed, "Refund not Allowed");
        require(_raffle.completed, "Raffle is still not completed");

        address[] memory listOfAddresses = _raffle.raffleContenders;
        for(uint256 i=0; i < listOfAddresses.length; i++){
            tokenOwner storage _tokenOwner = getOwner[listOfAddresses[i]];
            if(_tokenOwner.ticketForRaffle[_raffleId] > 0)
            {
                IAlphaSharkRewards(AlphaSharkRewards).updateAddLockTokens(_tokenOwner.ticketForRaffle[_raffleId].mul(10**18).mul(multiplier), _tokenOwner.owner, false);
                _tokenOwner.ticketForRaffle[_raffleId] = 0;
            }
        }
    }

    function removeActiveRaffle(uint256 _raffleId) internal {
        uint256 index = 0;
        bool flag = false;
        for(uint256 i=0; i<activeRaffleList.length; i++)
        {
            if(activeRaffleList[i] == _raffleId){
                index = i;
                flag = true;
            }
        }
        if(flag)
        {
            activeRaffleList[index] = activeRaffleList[activeRaffleList.length -1];
            activeRaffleList.pop();
        }
    }

    function generateRaffleWinner(uint256 _raffleId, uint256 _winnerCount) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
        Raffle storage _raffle = getRaffleDetails[_raffleId];
        require(!_raffle.completed, "Raffle completed");
        address[] memory listOfAddresses = _raffle.raffleContenders;
        require(listOfAddresses.length >= _winnerCount, "Addresses less than Winners");
        
        uint256 _totalRaffles = _raffle.totalRaffleTicket;
        for(uint256 j=0;j<_winnerCount;j++){
            uint256 currentRaffleCount = 0;
            uint256 raffleWinner = raffleNumberGenerator(_totalRaffles,j);
            for(uint256 i=0; i<listOfAddresses.length; i++){
                tokenOwner storage _tokenOwner = getOwner[listOfAddresses[i]];
                currentRaffleCount += _tokenOwner.ticketForRaffle[_raffleId];
                if(currentRaffleCount >= raffleWinner)
                {
                    _totalRaffles -= _tokenOwner.ticketForRaffle[_raffleId];
                    _tokenOwner.ticketForRaffle[_raffleId] = 0;
                    _raffle.raffleIdWinner.push(_tokenOwner.owner);
                    winnerList.push(_tokenOwner.owner);
                    break;
                }
            }
            _raffle.completed = true;
            _raffle.active = false;
            completedRaffleList.push(_raffleId);
            removeActiveRaffle(_raffleId);
            _raffle.endTime = block.timestamp;
        }
    }

    function raffleNumberGenerator(uint256 totalRaffles, uint256 index) internal view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + index + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number
        )));
        return  1 + (seed - ((seed / totalRaffles) * totalRaffles));
    }

    function getActiveRaffles() view public returns (Raffle[] memory) {
        Raffle[] memory _raffle = new Raffle[](activeRaffleList.length);
        for(uint256 i=0;i<activeRaffleList.length;i++){
            _raffle[i] = getRaffleDetails[activeRaffleList[i]];
        }
        return _raffle;
    }

    function getCompletedRaffle() view public returns (Raffle[] memory) {
        Raffle[] memory _raffle = new Raffle[](completedRaffleList.length);
        for(uint256 i=0;i<completedRaffleList.length;i++){
            _raffle[i] = getRaffleDetails[completedRaffleList[i]];
        }
        return _raffle;
    }

    function getUserData(address _address) view public returns (User[] memory) {
        User[] memory _user = userRaffleDetails[_address];
        return _user;
    }

    function getAllData(address _address) view external returns (Raffle[] memory, User[] memory, Raffle[] memory) {
        return (getActiveRaffles(), getUserData(_address), getCompletedRaffle());
    }
}