pragma solidity ^0.5.10;

contract CareerPlan {
    address owner;
    address smartLotto;

    struct LevelStatus {
        uint balance;
        address[] usersAddress;
        mapping(address => uint) usersIds;
    }

    mapping(uint8 => LevelStatus) public levelStatus;
    mapping(uint8 => uint) public levelAmountToDistribute;

    modifier onlySmartLotto () {
        require(smartLotto != address(0), 'required SmartLotto address');
        require(smartLotto == msg.sender, 'only SmartLotto');
        _;
    }

    modifier restricted () {
        require(smartLotto == msg.sender, 'restricted');
        _;
    }

    event UserUpgradeLevel(address indexed _user, uint indexed _userId, uint8 indexed _level);
    event UserEarned(address indexed _user, uint indexed _userId, uint8 indexed _level, uint _amount);

    constructor() public {
        owner = msg.sender;
        levelAmountToDistribute[1] = 1044873 * 1e6;
        levelAmountToDistribute[2] = 5433342 * 1e6;
        levelAmountToDistribute[3] = 10448735 * 1e6;
        levelAmountToDistribute[4] = 33435952 * 1e6;
        levelAmountToDistribute[5] = 83589880 * 1e6;
    }

    function setSmartLottoAddress(address _adr) external restricted {
        smartLotto = _adr;
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
        require(levelStatus[_level].usersIds[_user] == 0, 'User already exist');
        levelStatus[_level].usersIds[_user] = _id;
        levelStatus[_level].usersAddress.push(_user);
        applyDistribution();
        emit UserUpgradeLevel(_user, _id, _level);
    }

    function applyDistribution() internal {
        for(uint8 i = 1; i <= 5; i++) {
            if(levelStatus[i].balance >= levelAmountToDistribute[i]) {
                sendDistribution(i);
            }
        }
    }

    function sendDistribution(uint8 _level) internal {
        uint amount = levelAmountToDistribute[_level] / levelStatus[_level].usersAddress.length;
        for(uint8 i = 0; i < levelStatus[_level].usersAddress.length; i++) {
            address receiver = levelStatus[_level].usersAddress[i];
            if (!address(uint160(receiver)).send(amount)) {
                return address(uint160(receiver)).transfer(amount);
            }
            levelStatus[i].balance -= amount;
            emit UserEarned(receiver, levelStatus[_level].usersIds[receiver], _level, amount);
        }
    }
}
