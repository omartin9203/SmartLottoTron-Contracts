pragma solidity ^0.5.10;

contract CareerPlan {
    address payable admin;
    address public smartLotto;

    struct UserInfo {
        address addr;
        uint id;
    }

    struct LevelStatus {
        uint balance;
        mapping(uint => UserInfo) users;
        uint countUsers;
        uint next;
        uint waiting;
        uint currentAmount;
    }

    mapping(uint8 => LevelStatus) public levelStatus;
    mapping(uint8 => uint) public levelAmountToDistribute;

    modifier onlySmartLotto () {
        require(smartLotto != address(0), 'required SmartLotto address');
        require(smartLotto == msg.sender, 'only SmartLotto');
        _;
    }

    modifier restricted() {
        require(msg.sender == admin, "restricted");
        _;
    }

    event UserUpgradeLevel(address indexed _user, uint indexed _userId, uint8 indexed _level);
    event UserEarned(address indexed _user, uint indexed _userId, uint8 indexed _level, uint _amount);

    constructor() public {
        admin = msg.sender;
        levelAmountToDistribute[1] = 890168 * 1e6;
        levelAmountToDistribute[2] = 4628874 * 1e6;
        levelAmountToDistribute[3] = 8901681 * 1e6;
        levelAmountToDistribute[4] = 28485382 * 1e6;
        levelAmountToDistribute[5] = 83589880 * 1e6;
    }

    function setSmartLottoAddress(address contractAddress) external restricted {
        smartLotto = contractAddress;
    }

    function addToBalance() external payable {
        uint amount = msg.value / 5;
        levelStatus[1].balance += amount;
        levelStatus[2].balance += amount;
        levelStatus[3].balance += amount;
        levelStatus[4].balance += amount;
        levelStatus[5].balance += amount;
        applyDistribution();
    }

    function addUserToLevel(address _user, uint _id, uint8 _level) external onlySmartLotto {
        uint index = ++levelStatus[_level].countUsers;
        levelStatus[_level].users[index].addr = _user;
        levelStatus[_level].users[index].id = _id;
        applyDistribution();
        emit UserUpgradeLevel(_user, _id, _level);
    }

    function applyDistribution() internal {
        for(uint8 i = 1; i <= 5; i++) {
            if(levelStatus[i].waiting > 0) {
                applyDistributionLevel(i);
            }
            else if(levelStatus[i].balance >= levelAmountToDistribute[i] && levelStatus[i].countUsers > 0) {
                LevelStatus storage status = levelStatus[i];
                status.currentAmount = levelAmountToDistribute[i] / status.countUsers;
                status.waiting = status.countUsers;
                status.next = 1;
                applyDistributionLevel(i);
            }
        }
    }

    function applyDistributionLevel(uint8 _level) internal {
        LevelStatus storage status = levelStatus[_level];
        UserInfo memory receiver = status.users[status.next];
        if (!address(uint160(receiver.addr)).send(status.currentAmount)) {
            return address(uint160(receiver.addr)).transfer(status.currentAmount);
        }
        emit UserEarned(receiver.addr, receiver.id, _level, status.currentAmount);
        status.waiting--;
        status.next++;
        status.balance -= status.currentAmount;
        if(status.waiting == 0) {
            status.next = 0;
            status.currentAmount = 0;
        }
    }

    function getStatusOfLevel(uint8 level) external view returns(uint status, uint goal, uint next, uint waiting, uint amount) {
        status = levelStatus[level].balance;
        goal = levelAmountToDistribute[level];
        next = levelStatus[level].next;
        waiting = levelStatus[level].waiting;
        amount = levelStatus[level].currentAmount;
    }

    function withdrawLostTRXFromBalance() public restricted {
        admin.transfer(address(this).balance);
    }
}
