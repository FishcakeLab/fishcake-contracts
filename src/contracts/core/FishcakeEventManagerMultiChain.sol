// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin-upgrades/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";

/**
 * @title FishcakeEventManagerMultiChain
 * @notice Simplified multi-chain event management contract for Fishcake
 * @dev Core functionality: event creation, reward distribution, and verification
 * Supports USDT stablecoin-based activities across multiple chains
 */
contract FishcakeEventManagerMultiChain is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ============ Constants ============
    uint256 public constant MAX_DEADLINE = 30 days;
    uint256 public constant MIN_TOTAL_AMOUNT = 1e6; // 1 USDT (6 decimals)
    uint256 public constant MAX_DROP_NUMBER = 1000; // Maximum participants per event

    // ============ Enums ============
    enum DropType {
        FIXED,    // 1: Fixed amount per participant
        RANDOM    // 2: Random amount within range
    }

    enum ActivityStatus {
        ACTIVE,      // 0: Event is active
        FINISHED,    // 1: Event finished by creator
        EXPIRED      // 2: Event expired (deadline passed)
    }

    // ============ Structs ============
    struct ActivityInfo {
        uint256 activityId;
        address creator;
        string businessName;
        string activityContent;
        string location; // coordinates or location description
        uint256 createdAt;
        uint256 deadline;
        DropType dropType;
        uint256 totalDrops; // number of reward slots
        uint256 minDropAmount; // 0 for FIXED type
        uint256 maxDropAmount; // amount per drop for FIXED type
        address tokenAddress;
        uint256 totalAmount; // Total locked amount
        uint256 distributedAmount; // amount already distributed
        uint256 distributedCount; // this is the number of drops completed
        ActivityStatus status;
    }

    struct DropRecord {
        uint256 activityId;
        address recipient;
        uint256 amount;
        uint256 timestamp;
    }

    // ============ State Variables ============
    ActivityInfo[] public activities;
    DropRecord[] public dropRecords;
    
    // Activity ID => Recipient => Has received drop
    mapping(uint256 => mapping(address => bool)) public hasReceived;
    
    // Supported stablecoin tokens (address => is supported)
    mapping(address => bool) public supportedTokens;
    
    // Creator address => array of their activity IDs
    mapping(address => uint256[]) public creatorActivities;

    // ============ Events ============
    event ActivityCreated(
        uint256 indexed activityId,
        address indexed creator,
        string businessName,
        uint256 totalAmount,
        uint256 totalDrops,
        address tokenAddress,
        uint256 deadline
    );

    event DropDistributed(
        uint256 indexed activityId,
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );

    event ActivityFinished(
        uint256 indexed activityId,
        uint256 remainingAmount,
        uint256 distributedCount
    );

    event TokenSupportUpdated(
        address indexed tokenAddress,
        bool isSupported
    );

    // ============ Modifiers ============
    modifier validActivity(uint256 _activityId) {
        require(_activityId > 0 && _activityId <= activities.length, "Invalid activity ID");
        _;
    }

    modifier onlyCreator(uint256 _activityId) {
        require(
            activities[_activityId - 1].creator == msg.sender,
            "Not the activity creator"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ============ Initializer ============
    function initialize(
        address _initialOwner,
        address _usdtAddress
    ) public initializer {
        require(_initialOwner != address(0), "Invalid owner address");
        require(_usdtAddress != address(0), "Invalid USDT address");

        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        transferOwnership(_initialOwner);
        
        // USDT as supported token
        supportedTokens[_usdtAddress] = true;
        emit TokenSupportUpdated(_usdtAddress, true);
    }

    // ============ External Functions ============

    /**
     * @notice Create a new event with reward distribution
     * @param _businessName Name of the business or event creator
     * @param _activityContent Description of the event
     * @param _location Location information this could be coordinates or description...
     * @param _deadline Event expiration timestamp
     * @param _totalAmount Total amount to distribute
     * @param _dropType Type of distribution (FIXED or RANDOM)
     * @param _totalDrops Number of reward slots
     * @param _minDropAmount Minimum amount per drop (0 for FIXED)
     * @param _maxDropAmount Maximum or fixed amount per drop
     * @param _tokenAddress Token contract address must be supported
     * @return success Operation success status
     * @return activityId ID of created activity
     */
    function createActivity(
        string memory _businessName,
        string memory _activityContent,
        string memory _location,
        uint256 _deadline,
        uint256 _totalAmount,
        DropType _dropType,
        uint256 _totalDrops,
        uint256 _minDropAmount,
        uint256 _maxDropAmount,
        address _tokenAddress
    ) external nonReentrant whenNotPaused returns (bool success, uint256 activityId) {

        // Validation
        require(bytes(_businessName).length > 0, "Business name required");
        require(bytes(_activityContent).length > 0, "Activity content required");
        require(supportedTokens[_tokenAddress], "Token not supported");
        require(_totalAmount >= MIN_TOTAL_AMOUNT, "Amount too small");
        require(_totalDrops > 0 && _totalDrops <= MAX_DROP_NUMBER, "Invalid drop count");
        require(_deadline > block.timestamp, "Deadline must be in future");
        require(_deadline <= block.timestamp + MAX_DEADLINE, "Deadline too far");
        require(_maxDropAmount > 0, "Max drop amount must be positive");

        if (_dropType == DropType.RANDOM) {
            require(_maxDropAmount >= _minDropAmount, "Invalid amount range");
            require(_minDropAmount > 0, "Min amount must be positive for random");
            // for random, total should be able to cover max scenario
            require(_totalAmount >= _minDropAmount * _totalDrops, "Insufficient total for min drops");
        } else {
            // for FIXED type, total must equal max * drops
            require(_totalAmount == _maxDropAmount * _totalDrops, "Total must equal max * drops");
            _minDropAmount = 0; // Force to 0 for fixed type
        }

        // tansfer tokens to contract
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _totalAmount
        );

        // create activity
        activityId = activities.length + 1;
        
        ActivityInfo memory newActivity = ActivityInfo({
            activityId: activityId,
            creator: msg.sender,
            businessName: _businessName,
            activityContent: _activityContent,
            location: _location,
            createdAt: block.timestamp,
            deadline: _deadline,
            dropType: _dropType,
            totalDrops: _totalDrops,
            minDropAmount: _minDropAmount,
            maxDropAmount: _maxDropAmount,
            tokenAddress: _tokenAddress,
            totalAmount: _totalAmount,
            distributedAmount: 0,
            distributedCount: 0,
            status: ActivityStatus.ACTIVE
        });

        activities.push(newActivity);
        creatorActivities[msg.sender].push(activityId);

        emit ActivityCreated(
            activityId,
            msg.sender,
            _businessName,
            _totalAmount,
            _totalDrops,
            _tokenAddress,
            _deadline
        );

        return (true, activityId);
    }

    /**
     * @notice Distribute reward to a participant
     * @param _activityId ID of the activity
     * @param _recipient Address to receive the reward
     * @param _amount Amount to distribute must be within range for RANDOM type
     * @return success Operation success status
     */
    function distributeReward(
        uint256 _activityId,
        address _recipient,
        uint256 _amount
    )
        external
        nonReentrant
        whenNotPaused
        validActivity(_activityId)
        onlyCreator(_activityId)
        returns (bool success)
    {
        ActivityInfo storage activity = activities[_activityId - 1];

        // validations
        require(activity.status == ActivityStatus.ACTIVE, "Activity not active");
        require(block.timestamp <= activity.deadline, "Activity expired");
        require(_recipient != address(0), "Invalid recipient");
        require(!hasReceived[_activityId][_recipient], "Already received reward");
        require(activity.distributedCount < activity.totalDrops, "All rewards distributed");

        // validate amount based on drop type
        if (activity.dropType == DropType.FIXED) {
            require(_amount == activity.maxDropAmount, "Amount must equal fixed amount");
        } else {
            require(
                _amount >= activity.minDropAmount && _amount <= activity.maxDropAmount,
                "Amount outside allowed range"
            );
        }

        // check remaining funds
        uint256 remaining = activity.totalAmount - activity.distributedAmount;
        require(_amount <= remaining, "Insufficient remaining funds");

        // update state
        hasReceived[_activityId][_recipient] = true;
        activity.distributedAmount += _amount;
        activity.distributedCount++;

        // record drop
        dropRecords.push(DropRecord({
            activityId: _activityId,
            recipient: _recipient,
            amount: _amount,
            timestamp: block.timestamp
        }));

        // reward transfer
        IERC20Upgradeable(activity.tokenAddress).safeTransfer(_recipient, _amount);

        emit DropDistributed(_activityId, _recipient, _amount, block.timestamp);

        return true;
    }

    /**
     * @notice Finish an activity and return remaining funds
     * @param _activityId ID of the activity to finish
     * @return success Operation success status
     */
    function finishActivity(uint256 _activityId)
        external
        nonReentrant
        whenNotPaused
        validActivity(_activityId)
        onlyCreator(_activityId)
        returns (bool success)
    {
        ActivityInfo storage activity = activities[_activityId - 1];

        require(activity.status == ActivityStatus.ACTIVE, "Activity already finished");

        // calculate remaining amount
        uint256 remainingAmount = activity.totalAmount - activity.distributedAmount;

        // update status
        activity.status = ActivityStatus.FINISHED;

        // return remaining funds if any
        if (remainingAmount > 0) {
            IERC20Upgradeable(activity.tokenAddress).safeTransfer(
                msg.sender,
                remainingAmount
            );
        }

        emit ActivityFinished(_activityId, remainingAmount, activity.distributedCount);

        return true;
    }

    /**
     * @notice Mark expired activities
     * @param _activityIds Array of activity IDs to check and mark as expired
     */
    function markExpiredActivities(uint256[] calldata _activityIds) external {
        for (uint256 i = 0; i < _activityIds.length; i++) {
            uint256 activityId = _activityIds[i];
            if (activityId > 0 && activityId <= activities.length) {
                ActivityInfo storage activity = activities[activityId - 1];
                
                if (
                    activity.status == ActivityStatus.ACTIVE &&
                    block.timestamp > activity.deadline
                ) {
                    activity.status = ActivityStatus.EXPIRED;
                    
                    // return remaining funds to creator
                    uint256 remaining = activity.totalAmount - activity.distributedAmount;
                    if (remaining > 0) {
                        IERC20Upgradeable(activity.tokenAddress).safeTransfer(
                            activity.creator,
                            remaining
                        );
                    }
                    
                    emit ActivityFinished(activityId, remaining, activity.distributedCount);
                }
            }
        }
    }

    // ============ View Functions ============

    /**
     * @notice Get activity details
     * @param _activityId ID of the activity
     * @return Activity information
     */
    function getActivity(uint256 _activityId)
        external
        view
        validActivity(_activityId)
        returns (ActivityInfo memory)
    {
        return activities[_activityId - 1];
    }

    /**
     * @notice Get total number of activities
     */
    function getActivityCount() external view returns (uint256) {
        return activities.length;
    }

    /**
     * @notice Check if user has received reward for an activity
     * @param _activityId ID of the activity
     * @param _user Address to check
     */
    function hasUserReceived(uint256 _activityId, address _user)
        external
        view
        returns (bool)
    {
        return hasReceived[_activityId][_user];
    }

    /**
     * @notice Get activities created by a specific address
     * @param _creator Creator address
     */

    function getCreatorActivities(address _creator)
        external
        view
        returns (uint256[] memory)
    {
        return creatorActivities[_creator];
    }

    /**
     * @notice Get total number of drop records
     */
    function getDropRecordCount() external view returns (uint256) {
        return dropRecords.length;
    }

    /**
     * @notice Get drop record by index
     * @param _index Index in dropRecords array
     */
    function getDropRecord(uint256 _index)
        external
        view
        returns (DropRecord memory)
    {
        require(_index < dropRecords.length, "Index out of bounds");
        return dropRecords[_index];
    }

    /**
     * @notice Verify an activity and participant eligibility
     * @param _activityId ID of the activity
     * @param _participant Address to verify
     * @return isValid True if activity is valid and participant is eligible
     * @return reason Reason if not valid
     */
    function verifyParticipant(uint256 _activityId, address _participant)
        external
        view
        validActivity(_activityId)
        returns (bool isValid, string memory reason)
    {
        ActivityInfo memory activity = activities[_activityId - 1];

        if (activity.status != ActivityStatus.ACTIVE) {
            return (false, "Activity not active");
        }

        if (block.timestamp > activity.deadline) {
            return (false, "Activity expired");
        }

        if (hasReceived[_activityId][_participant]) {
            return (false, "Already received reward");
        }

        if (activity.distributedCount >= activity.totalDrops) {
            return (false, "All rewards distributed");
        }

        return (true, "Eligible");
    }

    // ============ Admin Functions ============

    /**
     * @notice Add or remove supported token
     * @param _tokenAddress Token contract address
     * @param _isSupported True to support, false to remove support
     */
    function setSupportedToken(address _tokenAddress, bool _isSupported)
        external
        onlyOwner
    {
        require(_tokenAddress != address(0), "Invalid token address");
        supportedTokens[_tokenAddress] = _isSupported;
        emit TokenSupportUpdated(_tokenAddress, _isSupported);
    }

    /**
     * @notice Pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Emergency withdrawal (justfor stuck funds, not from active activities)
     * @param _token Token address
     * @param _amount Amount to withdraw
     */
    function emergencyWithdraw(address _token, uint256 _amount)
        external
        onlyOwner
    {
        require(_token != address(0), "Invalid token");
        
        // clculate total locked in active activities
        uint256 totalLocked = 0;
        for (uint256 i = 0; i < activities.length; i++) {
            if (
                activities[i].status == ActivityStatus.ACTIVE &&
                activities[i].tokenAddress == _token
            ) {
                totalLocked += (activities[i].totalAmount - activities[i].distributedAmount);
            }
        }

        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        uint256 available = balance - totalLocked;
        
        require(_amount <= available, "Cannot withdraw from active activities");
        
        IERC20Upgradeable(_token).safeTransfer(owner(), _amount);
    }

    // ============ Gap for Upgrade Safety ============
    uint256[50] private __gap;
}