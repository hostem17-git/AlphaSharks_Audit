// File: contracts/SmartChefInitializable.sol
// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RewardSharks is Ownable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant STAKE_ROLE = keccak256("STAKE_ROLE");
    bytes32 public constant CLAIM_ROLE = keccak256("CLAIM_ROLE");
    bytes32 public constant BOOST_ROLE = keccak256("BOOST_ROLE");

    // The Alpha Shark Token
    IERC20 public rewardTokenAddress;

    address raffleAddress;
    address dutchRaffle;

    // The address of the smart chef factory
    address public ALPHA_SHARK_FACTORY;

    // Whether it is initialized
    bool public isInitialized;

    // Token Decimals
    uint256 public tokenDecimals = 18;

    // Rewards Claims
    bool public claimAllowed = true;

    mapping(address => uint256[]) public ownerTokenList;

    mapping(address => uint256) public totalTokens; // Address => Total Tokens

    mapping(address => uint256) public lockedTokens; // Address => Locked Tokens

    // Reward Token Mapping (Token Id => Reward ) Rewards --> Tokens/Day
    mapping(uint256 => uint256) public tokenIdReward;

    struct Boosts {
        uint256 boost_type;
        uint boostAmountPercentage; 
        uint256 expireTimeStamp;
    }

    struct Sharks {
        uint256 sharkId;
        uint256 stakingTimeStamp;
        uint256 lastClaimTimeStamp;
        address ownerAddress;
        bool tokenStaked; 
        uint256[] activeBoost;
        bool shiver;
        uint shiverId;
    }

    Boosts[] public listOfBoosters;
    // Boost_type => Boosts
    mapping(uint256 => Boosts) public getBooster;

    // sharkId => Sharks
    mapping(uint256 => Sharks) public getSharks;

    // Active Shiver Counter Missing ?
    uint256 public shiverCounter = 0;
    // ShiverID => Shiver Token List
    mapping(uint256 => uint256[]) public getShiver;

    // List of alloted boost for addresses
    mapping(address => uint256[]) public availableBoosts;

    // Event Stake
    // Event Shiver
    // Event Unstake
    // Event Shiver Break
    // Claim rewards
    // Toggle Claim Status
    // event Stake(address indexed user, uint256 amount);
    // event RewardsStop(uint256 blockNumber);
    // event Withdraw(address indexed user, uint256 amount);

    constructor() ReentrancyGuard() {
        ALPHA_SHARK_FACTORY = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*
     * @notice Initialize the contract
     * @param _rewardToken: reward token address
     * @param _admin: admin address with ownership
     */
    function initialize(
        IERC20 _rewardTokenAddress,
        address _raffleAddress,
        address _dutchRaffle,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == ALPHA_SHARK_FACTORY, "Not factory");

        // Make this contract initialized
        isInitialized = true;
        rewardTokenAddress = _rewardTokenAddress;
        raffleAddress = _raffleAddress;
        dutchRaffle = _dutchRaffle;
        transferOwnership(_admin);
    }

    function updateRewardAddress(IERC20 _rewardTokenAddress) external onlyOwner {
        rewardTokenAddress = _rewardTokenAddress;
    }

    function toggleClaimReward() external onlyOwner {
        claimAllowed = !claimAllowed;
    }

    function ifBoostTypeAvailable(uint256 _boostType) public view returns (bool) {
        for(uint256 i=0; i<listOfBoosters.length; i++)
        {
            if(listOfBoosters[i].boost_type == _boostType)
            {
                return false;
            }
        }
        return true;
    }

    function addBooster(uint256 _boostType, uint _boostPercentage, uint256 _expireTimeStamp) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        require(ifBoostTypeAvailable(_boostType), "Boost Type Not Available");
        Boosts memory b1;
        b1.boost_type = _boostType;
        b1.boostAmountPercentage = _boostPercentage;
        b1.expireTimeStamp = _expireTimeStamp;
        listOfBoosters.push(b1);
        getBooster[_boostType] = b1;
    }

    function assignBooster(address _address, uint256 _boostType) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        require(!ifBoostTypeAvailable(_boostType), "Boost Type Not Available");
        availableBoosts[_address].push(_boostType);
    }

    function userBoostAvailabitiy(uint256 _boostType) internal returns (bool) {
        uint256[] storage listOfBoosts = availableBoosts[msg.sender];
        uint256 index = 0;
        bool flag = false;
        for(uint256 i=0; i<listOfBoosts.length; i++)
        {
            if(listOfBoosts[i] == _boostType){
                index = i;
                flag = true;
            }
        }
        if(flag)
        {
            listOfBoosts[index] = listOfBoosts[listOfBoosts.length -1 ];
            listOfBoosts.pop();
            return true;
        }
        else{
            return false;
        }
    }

    function returnSingleSharkData(uint256 _tokenID) external view returns (Sharks memory) {
        return getSharks[_tokenID];
    }

    function returnOwnerAllSharkData(address _address) external view returns (Sharks[] memory,Boosts[] memory, uint256[] memory, Boosts[] memory) {
        require(ownerTokenList[_address].length > 0, "No Tokens Staked");

        //Sharks
        Sharks[] memory _shark = new Sharks[](ownerTokenList[_address].length);
        uint256 _boostCounter = 0;
        for(uint256 i=0; i<ownerTokenList[_address].length; i++){
            _shark[i] = getSharks[ownerTokenList[_address][i]];
            _boostCounter += getSharks[ownerTokenList[_address][i]].activeBoost.length;
        }
        
        // Boosts
        Boosts[] memory _boosts = new Boosts[](_boostCounter);
        uint256 currentBoostCounter = 0;
        for(uint256 i=0; i<ownerTokenList[_address].length; i++){
            Sharks memory _sharkTemp = getSharks[ownerTokenList[_address][i]];
            for(uint256 j=0; j<_sharkTemp.activeBoost.length; j++){
                _boosts[currentBoostCounter] = getBooster[_sharkTemp.activeBoost[j]];
                currentBoostCounter +=1;
            }
        }

        // Available Tokens
        uint256[] memory _tokenDetails = new uint256[](3);
        _tokenDetails[0] = totalTokens[_address];
        _tokenDetails[1] = lockedTokens[_address];
        _tokenDetails[2] = availableTokens(_address);

        // Available Boosts
        uint256[] memory _tempAvailableBoosts = availableBoosts[_address];
        Boosts[] memory _boostsAvailable = new Boosts[](_tempAvailableBoosts.length);
        uint256 counter2 = 0;
        for(uint256 i=0; i<_tempAvailableBoosts.length; i++){
            _boostsAvailable[counter2] = getBooster[_tempAvailableBoosts[i]];
            counter2 += 1;
        }
        
        return (_shark, _boosts, _tokenDetails, _boostsAvailable);
    }

    function getOwnerList(address _address) external view returns (uint256[] memory) {
        return ownerTokenList[_address];
    }

    function getActiveBoost(uint256 _tokenId, uint256 activeBoostNumber) external view returns (uint256) {
        Sharks memory _shark = getSharks[_tokenId];
        return _shark.activeBoost[activeBoostNumber];
    }
 
    function activateBooster(uint256 _boostType, uint256 _tokenId) external {
        require(userBoostAvailabitiy(_boostType), "Boost is not available");
        Sharks storage _shark = getSharks[_tokenId];
        require(_shark.tokenStaked , "Token is not staked");
        _shark.activeBoost.push(_boostType);
        getSharks[_tokenId] = _shark;
    }

    function checkFixedBooster(uint256 _tokenId) public view returns (uint256) {
        // Add require staked statement 
        // S1 Booster
        Sharks memory _shark = getSharks[_tokenId];
        if(!_shark.tokenStaked){
            return 0;
        }
        uint256 rewardAdder = 0;
        if(_tokenId<1000)
        {
            rewardAdder = rewardAdder + 30;
        }
        else if(_tokenId%2==1)
        {
            rewardAdder = rewardAdder + 10;
        }
        uint256 timeDiffMonth = (block.timestamp -  _shark.stakingTimeStamp) / 30 days;
        rewardAdder = rewardAdder + timeDiffMonth.mul(5);
        return (rewardAdder > 100 ? 100: rewardAdder); 
    }

    function calculateTotalRewards(uint256 _tokenId) public view returns (uint) {
        Sharks memory _shark = getSharks[_tokenId];
        if(!_shark.tokenStaked){
            return 0;
        }
        uint rewardPercent = checkFixedBooster(_tokenId);
        // S2 Booster
        if(_shark.shiver)
        {
            rewardPercent = rewardPercent + 100;
        }
        uint256[] memory activeBoosters = _shark.activeBoost;
        // S3 Booster
        uint rewardPercentS3 = 0;
        for(uint256 i=0;i<activeBoosters.length;i++)
        {
            Boosts memory _boost = getBooster[activeBoosters[i]];
            if(_boost.expireTimeStamp > block.timestamp)
            {
                rewardPercentS3 = rewardPercentS3 + _boost.boostAmountPercentage;
            }
        }
        rewardPercent = rewardPercent + (rewardPercentS3 > 100 ? 100: rewardPercentS3);
        return rewardPercent;
    }

    function claimRewards(uint256 _tokenId) public {
        require(hasRole(CLAIM_ROLE, msg.sender), "Caller is not a claimer");
        require(claimAllowed, "Rewards Stopped");
        Sharks storage _shark = getSharks[_tokenId];
        if(!_shark.tokenStaked){
            return ;
        }
        uint256 rewardPercent = calculateTotalRewards(_tokenId);

        // Calculate Reward Amount
        uint256 rewardPerMinute = tokenIdReward[_tokenId].mul(10 ** 18).div(24).div(60);
        uint256 timeElapsed = (block.timestamp - _shark.lastClaimTimeStamp) / 1 minutes; 
        uint256 amountReward = timeElapsed.mul(rewardPerMinute).mul(100 + rewardPercent).div(100);

        _shark.lastClaimTimeStamp = block.timestamp;
        totalTokens[_shark.ownerAddress] += amountReward;
    }

    function claimAll(uint256 _totalTokens) external {
        require(hasRole(CLAIM_ROLE, msg.sender), "Caller is not a claimer");
        for(uint256 i=0; i <= _totalTokens; i++) {
            claimRewards(i);
        }
    }

    modifier onlyNFT {
        require(msg.sender == raffleAddress, "Can be only accessed by Raffle Contract");
        _;
    }

    modifier onlyDutchRaffle {
        require(msg.sender == dutchRaffle, "Can be only accessed by Dutch Raffle Contract");
        _;
    }

    // True ==> Add
    // False ==> Subtract
    function updateAddLockTokens(uint256 _amount, address _address,bool _add) external onlyNFT {
        if(_add){
            lockedTokens[_address] += _amount;
        }
        else{
            lockedTokens[_address] -= _amount;
        }
    }

    function updateTotalLockTokens(uint256 _amount, address _address) external onlyDutchRaffle {
        require(totalTokens[_address] >= _amount, "Insufficient Balance");
        totalTokens[_address] -= _amount;
    }

    function availableTokens(address _address) public view returns (uint256) {
        return (totalTokens[_address] - lockedTokens[_address]);
    }

    function withdawTokens(uint256 _amount) external {
        require(availableTokens(msg.sender) >= _amount, "Insufficient Tokens");
        rewardTokenAddress.transfer(msg.sender, _amount);
        totalTokens[msg.sender] -= _amount;
    }

    function depositTokens(uint256 _amount) external {
        rewardTokenAddress.transferFrom(msg.sender,address(this), _amount);
        totalTokens[msg.sender] += _amount;
    }

    function stakeNFT(uint256 _tokenId, address _address) external {
        require(hasRole(STAKE_ROLE, msg.sender), "Caller is not a staker");
        Sharks memory _shark = getSharks[_tokenId];
        require(!_shark.tokenStaked, "Token is Already Staked");
        
        _shark.lastClaimTimeStamp = block.timestamp;
        _shark.stakingTimeStamp = block.timestamp;
        _shark.sharkId = _tokenId;
        _shark.tokenStaked = true;
        _shark.ownerAddress = _address;
        _shark.activeBoost;
        
        getSharks[_tokenId] = _shark;
        ownerTokenList[_address].push(_tokenId);
        // Emit Event Stake
    }

    function checkShiverBreak(uint256 _tokenId) internal {
        Sharks memory _shark = getSharks[_tokenId];
        if(_shark.shiver==true)
        {
            uint256 ShiverID = _shark.shiverId;
            uint256[] memory shiverTokenList = getShiver[ShiverID];
            for(uint256 i=0;i<shiverTokenList.length;i++)
            {
                getSharks[shiverTokenList[i]].shiver = false;
                getSharks[shiverTokenList[i]].shiverId = 0;
            }
        }
    }

    function removeTokenFromOwnerList(uint256 _tokenId) internal {
        uint256[] storage listOfTokens = ownerTokenList[getSharks[_tokenId].ownerAddress];
        uint256 index = 0;
        bool flag = false;
        for(uint256 i=0; i<listOfTokens.length; i++)
        {
            if(listOfTokens[i] == _tokenId){
                index = i;
                flag = true;
            }
        }
        if(flag)
        {
            listOfTokens[index] = listOfTokens[listOfTokens.length -1];
            listOfTokens.pop();
        }
        ownerTokenList[getSharks[_tokenId].ownerAddress] = listOfTokens;
    }

    function unStakeNFT(uint256 _tokenId) external {
        require(hasRole(STAKE_ROLE, msg.sender), "Caller is not a staker");
        require(getSharks[_tokenId].tokenStaked, "Token is not Staked");
        getSharks[_tokenId].tokenStaked = false;
        
        checkShiverBreak(_tokenId);
        removeTokenFromOwnerList(_tokenId);
        // Emit Event Unstake
    }
    
    function makeShiver(uint256[] memory listOfTokens) external {
        require(listOfTokens.length==5, "Shiver can be only made with 5 Tokens");
        for(uint256 i=0;i<5;i++){
            Sharks memory _shark = getSharks[listOfTokens[i]];
            require(_shark.shiver==false, "Shiver already activated for this token");
            require(_shark.ownerAddress==msg.sender || ALPHA_SHARK_FACTORY==msg.sender || hasRole(BOOST_ROLE, msg.sender), "You are not the owner of all NFT's");
        }
        shiverCounter = shiverCounter + 1;
        for(uint256 i=0;i<5;i++){
            Sharks memory _shark = getSharks[listOfTokens[i]];
            _shark.shiverId = shiverCounter;
            _shark.shiver = true;
            getSharks[listOfTokens[i]] = _shark;
        }
        getShiver[shiverCounter] = listOfTokens;
    }

    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardTokenAddress.safeTransfer(address(msg.sender), _amount);
    }

    function stopBooster(uint256 _boostType) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        Boosts storage _boost = getBooster[_boostType];
        _boost.expireTimeStamp = block.timestamp;
    }

    function updateAllRewards(uint256[] memory _rewards, uint256[] memory _tokenIds) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        require(_rewards.length==_tokenIds.length,"Length of Arrays Should be Equal");
        for(uint256 i=0;i<_rewards.length;i++)
        {
            tokenIdReward[_tokenIds[i]] = _rewards[i];
        }
    }

    function updateSingleReward(uint256 _reward, uint256 _tokenId) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        tokenIdReward[_tokenId] = _reward;
    }

}