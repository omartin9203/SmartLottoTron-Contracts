// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;

import "./CareerPlan.sol";
import "./Lotto.sol";

contract SmartLotto {
    event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
    event NewUserChildEvent(address indexed _user, address indexed _sponsor, uint8 _box, bool _isSmartDirect, uint8 _position);
    event ReinvestBoxEvent(address indexed _user, address indexed currentSponsor, address indexed addrCaller, uint8 _box, bool _isSmartDirect);
    event MissedEvent(address indexed _from, address indexed _to, uint8 _box, bool _isSmartDirect);
    event SentExtraEvent(address indexed _from, address indexed _to, uint8 _box, bool _isSmartDirect);
    event UpgradeStatusEvent(address indexed _user, address indexed _sponsor, uint8 _box, bool _isSmartDirect);

    struct SmartTeamBox {
        bool purchased;
        bool inactive;
        uint reinvests;
        address closedAddr;
        address[] firstLevelChilds;
        address[] secondLevelChilds;
        address currentSponsor;
        uint partnersCount;
    }

    struct SmartDirectBox {
        bool purchased;
        bool inactive;
        uint reinvests;
        address[] childs;
        address currentSponsor;
        uint partnersCount;
    }

    struct User {
        uint id;
        uint partnersCount;
        mapping(uint8=>SmartDirectBox) directBoxes;
        mapping(uint8=>SmartTeamBox) teamBoxes;
        address sponsor;
        uint8 levelCareerPlan;
        bool activeInLottery;
    }

    uint nextId = 1;
    address payable externalAddress;
    address payable externalFeeAddress;
    mapping(address=>User) public users;
    mapping(uint=>address payable) public idLookup;

    CareerPlan careerPlan;
    struct PlanRequirements {
        uint purchasedBoxes;
        uint countReferrers;
    }
    mapping(uint8 => PlanRequirements) levelRequirements;
    Lotto lottery;

    mapping(uint8 => uint) public boxesValues;
    mapping(uint8 => uint) public boxes70PtgValues;
    mapping(uint8 => uint) public boxesExternalValues;
    mapping(uint8 => uint) public boxesPlanValues;

    modifier validSponsor(address _sponsor) {
        require(users[_sponsor].id != 0, "This sponsor does not exists");
        _;
    }

    modifier onlyUser() {
        require(users[msg.sender].id != 0, "This user does not exists");
        _;
    }

    modifier validNewUser(address _newUser) {
        uint32 size;
        assembly {
            size := extcodesize(_newUser)
        }
        require(size == 0, "The new user cannot be a contract");
        require(users[_newUser].id == 0, "This user already exists");
        _;
    }

    modifier validBox(uint _box) {
        require(_box >= 1 && _box <= 14, "Invalid box");
        _;
    }

    constructor(address payable _externalAddress, address payable _careerPlanAddress, address payable _lotteryAddress, address payable _externalFeeAddress) public {
        externalAddress = _externalAddress;
        externalFeeAddress = _externalFeeAddress;
        lottery = Lotto(_lotteryAddress);
        initializeCareerPlan(_careerPlanAddress);
        User storage root = users[externalAddress];
        root.id = nextId++;
        idLookup[root.id] = externalAddress;
        for (uint8 i = 1; i <= 14; i++) {
            boxesValues[i] = 250 * 1e6 * (2**(i - 1));
            boxes70PtgValues[i] = 175 * 1e6 * (2**(i - 1));
            boxesExternalValues[i] = 52.5 * 1e6 * (2**(i - 1));
            boxesPlanValues[i] = 22.5 * 1e6 * (2**(i - 1));
            
            root.directBoxes[i].purchased = true;
            root.teamBoxes[i].purchased = true;
        }
    }

    function initializeCareerPlan(address payable _careerPlanAddress) internal {
        careerPlan = CareerPlan(_careerPlanAddress);
        levelRequirements[1].countReferrers = 10;
        levelRequirements[1].purchasedBoxes = 3;
        levelRequirements[2].countReferrers = 20;
        levelRequirements[2].purchasedBoxes = 6;
        levelRequirements[3].countReferrers = 30;
        levelRequirements[3].purchasedBoxes = 9;
        levelRequirements[4].countReferrers = 40;
        levelRequirements[4].purchasedBoxes = 12;
        levelRequirements[5].countReferrers = 60;
        levelRequirements[5].purchasedBoxes = 14;
    }

    function() external payable {
        if(msg.data.length == 0) return signUp(msg.sender, externalAddress);
        address sponsor;
        bytes memory data = msg.data;
        assembly {
            sponsor := mload(add(data, 20))
        }
        signUp(msg.sender, sponsor);
    }

    function signUp(address payable _newUser, address _sponsor) private validSponsor(_sponsor) validNewUser(_newUser) {
        require(msg.value == 500 * 1e6, "Please enter required amount");

        // user node data
        User storage userNode = users[_newUser];
        userNode.id = nextId++;
        userNode.sponsor = _sponsor;
        userNode.directBoxes[1].purchased = true;
        userNode.teamBoxes[1].purchased = true;
        idLookup[userNode.id] = _newUser;

        users[_sponsor].partnersCount++;
        users[_sponsor].directBoxes[1].partnersCount++;
        users[_sponsor].teamBoxes[1].partnersCount++;
        userNode.directBoxes[1].currentSponsor = _sponsor;
        modifySmartDirectSponsor(_sponsor, _newUser, 1);
        modifySmartTeamSponsor(_sponsor, _newUser, 1);
        emit SignUpEvent(_newUser, userNode.id, _sponsor,  users[_sponsor].id);
    }

    function signUp(address sponsor) external payable {
        signUp(msg.sender, sponsor);
    }

    function buyNewBox(uint8 _matrix, uint8 _box) external payable onlyUser validBox(_box) {
        require(_matrix == 1 || _matrix == 2, "Invalid matrix");
        require(msg.value == boxesValues[_box], "Please enter required amount");
        if (_matrix == 1) {
            require(!users[msg.sender].directBoxes[_box].purchased, "You already bought that box");
            require(users[msg.sender].directBoxes[_box - 1].purchased, "Please bought the boxes prior to this");

            users[msg.sender].directBoxes[_box].purchased = true;
            users[msg.sender].directBoxes[_box - 1].inactive = false;
            address sponsorResult = findSponsor(msg.sender, _box, true);
            users[msg.sender].directBoxes[_box].currentSponsor = sponsorResult;
            modifySmartDirectSponsor(sponsorResult, msg.sender, _box);
            if(users[users[msg.sender].sponsor].directBoxes[_box].purchased) {
                users[users[msg.sender].sponsor].directBoxes[_box].partnersCount++;
                verifyLevelOfUser(users[msg.sender].sponsor);
            }
            emit UpgradeStatusEvent(msg.sender, sponsorResult, _box, true);
        } else {
            require(!users[msg.sender].teamBoxes[_box].purchased, "You already bought that box");
            require(users[msg.sender].teamBoxes[_box - 1].purchased, "Please bought the boxes prior to this");

            users[msg.sender].teamBoxes[_box].purchased = true;
            users[msg.sender].teamBoxes[_box - 1].inactive = false;
            address sponsorResult = findSponsor(msg.sender, _box, false);
            modifySmartTeamSponsor(sponsorResult, msg.sender, _box);
            if(users[users[msg.sender].sponsor].teamBoxes[_box].purchased) {
                users[users[msg.sender].sponsor].teamBoxes[_box].partnersCount++;
                verifyLevelOfUser(users[msg.sender].sponsor);
            }

            emit UpgradeStatusEvent(msg.sender, sponsorResult, _box, false);
        }
        verifyRequirementsForLottery(msg.sender);
    }

    function verifyLevelOfUser(address user) internal {
        if (users[user].levelCareerPlan >= 5) return;
        uint8 level = users[user].levelCareerPlan + 1;
        PlanRequirements memory requirements = levelRequirements[level];
        for(uint8 i; i < requirements.purchasedBoxes; i++) {
            if(!users[user].directBoxes[i].purchased || !users[user].teamBoxes[i].purchased) return;
            if(users[user].directBoxes[i].partnersCount < requirements.countReferrers
                || users[user].teamBoxes[i].partnersCount < requirements.countReferrers) return;
        }
        users[user].levelCareerPlan = level;
        careerPlan.addUserToLevel(user, users[user].id, level);
    }

    function verifyRequirementsForLottery(address user) internal {
        if (users[user].activeInLottery) return;
        for(uint8 i; i < 3; i++) {
            if(!users[user].directBoxes[i].purchased || !users[user].teamBoxes[i].purchased)
                return;
        }
        users[user].activeInLottery = true;
        lottery.addUser(user);
    }

    function modifySmartDirectSponsor(address _sponsor, address _user, uint8 _box) private {
        users[_sponsor].directBoxes[_box].childs.push(_user);
        uint8 position = uint8(users[_sponsor].directBoxes[_box].childs.length);
        emit NewUserChildEvent(_user, _sponsor, _box, true, position);
        if (position < 3)
            return applyDistribution(_user, _sponsor, _box, true);
        SmartDirectBox storage directData = users[_sponsor].directBoxes[_box];
        directData.childs = new address[](0);
        if (!users[_sponsor].directBoxes[_box + 1].purchased && _box != 14) directData.inactive = true;
        directData.reinvests++;
        if (externalAddress != _sponsor) {
            address sponsorResult = findSponsor(_sponsor, _box, true);
            directData.currentSponsor = sponsorResult;
            emit ReinvestBoxEvent(_sponsor, sponsorResult, _user, _box, true);
            modifySmartDirectSponsor(sponsorResult, _sponsor, _box);
        } else {
            applyDistribution(_user, _sponsor, _box, true);
            emit ReinvestBoxEvent(_sponsor, address(0), _user, _box, true);
        }
    }

    function findSponsor(address _addr, uint8 _box, bool _isSmartDirect) internal view returns(address) {
        User memory node = users[_addr];
        bool purchased;
        if (_isSmartDirect) purchased = users[node.sponsor].directBoxes[_box].purchased;
        else purchased = users[node.sponsor].teamBoxes[_box].purchased;
        if (purchased) return node.sponsor;
        return findSponsor(node.sponsor, _box, _isSmartDirect);
    }

    function modifySmartTeamSponsor(address _sponsor, address _user, uint8 _box) private {
        SmartTeamBox storage sponsorBoxData = users[_sponsor].teamBoxes[_box];

        if (sponsorBoxData.firstLevelChilds.length < 2) {
            sponsorBoxData.firstLevelChilds.push(_user);
            users[_user].teamBoxes[_box].currentSponsor = _sponsor;
            emit NewUserChildEvent(_user, _sponsor, _box, false, uint8(sponsorBoxData.firstLevelChilds.length));

            if (_sponsor == externalAddress)
                return applyDistribution(_user, _sponsor, _box, false);

            address currentSponsor = sponsorBoxData.currentSponsor;
            users[currentSponsor].teamBoxes[_box].secondLevelChilds.push(_user);

            uint8 len = uint8(users[currentSponsor].teamBoxes[_box].firstLevelChilds.length);

            for(uint8 i = len - 1; i >= 0; i++) {
                if(users[currentSponsor].teamBoxes[_box].firstLevelChilds[i] == _sponsor) {
                    emit NewUserChildEvent(_user, currentSponsor, _box, false, uint8((2 * (i + 1)) + sponsorBoxData.firstLevelChilds.length));
                    break;
                }
            }

            return modifySmartTeamSecondLevel(_user, currentSponsor, _box);
        }

        sponsorBoxData.secondLevelChilds.push(_user);

        if (sponsorBoxData.closedAddr != address(0)) {
            uint8 index;
            if (sponsorBoxData.firstLevelChilds[0] == sponsorBoxData.closedAddr) {
                index = 1;
            }
            modifySmartTeam(_sponsor, _user, _box, index);
            return modifySmartTeamSecondLevel(_user, _sponsor, _box);
        }

        for(uint8 i = 0;i < 2;i++) {
            if(sponsorBoxData.firstLevelChilds[i] == _user) {
                modifySmartTeam(_sponsor, _user, _box, i^1);
                return modifySmartTeamSecondLevel(_user, _sponsor, _box);
            }
        }
        uint8 index = 1;
        if (users[sponsorBoxData.firstLevelChilds[0]].teamBoxes[_box].firstLevelChilds.length <=
            users[sponsorBoxData.firstLevelChilds[1]].teamBoxes[_box].firstLevelChilds.length) {
            index = 0;
        }
        modifySmartTeam(_sponsor, _user, _box, index);
        modifySmartTeamSecondLevel(_user, _sponsor, _box);
    }

    function modifySmartTeam(address _sponsor, address _user, uint8 _box, uint8 _index) private {
        User storage userData = users[_user];
        User storage sponsorData = users[_sponsor];
        address chieldAddress = sponsorData.teamBoxes[_box].firstLevelChilds[_index];
        User storage childData = users[chieldAddress];
        childData.teamBoxes[_box].firstLevelChilds.push(_user);
        uint8 length = uint8(childData.teamBoxes[_box].firstLevelChilds.length);
        uint position = (2**(_index + 1)) + length;
        emit NewUserChildEvent(_user, chieldAddress, _box, false, length);
        emit NewUserChildEvent(_user, _sponsor, _box, false, uint8(position));
        userData.teamBoxes[_box].currentSponsor = chieldAddress;
    }

    function modifySmartTeamSecondLevel(address _user, address _sponsor, uint8 _box) private {
        User storage sponsorData = users[_sponsor];
        if (sponsorData.teamBoxes[_box].secondLevelChilds.length < 4)
            return applyDistribution(_user, _sponsor, _box, false);

        User storage currentSponsorData = users[sponsorData.teamBoxes[_box].currentSponsor];
        address[] memory childs = currentSponsorData.teamBoxes[_box].firstLevelChilds;

        for(uint8 i = 0;i < childs.length;i++) {
            if(childs[i] == _sponsor)
                currentSponsorData.teamBoxes[_box].closedAddr = _sponsor;
        }
        sponsorData.teamBoxes[_box].firstLevelChilds = new address[](0);
        sponsorData.teamBoxes[_box].secondLevelChilds = new address[](0);
        sponsorData.teamBoxes[_box].closedAddr = address(0);
        sponsorData.teamBoxes[_box].reinvests++;

        if (!sponsorData.teamBoxes[_box + 1].purchased && _box != 14)
            sponsorData.teamBoxes[_box].inactive = true;

        if (sponsorData.id == 1) {
            emit ReinvestBoxEvent(_sponsor, address(0), _user, _box, false);
            return applyDistribution(_user, _sponsor, _box, false);
        }
        address sponsorResult = findSponsor(_sponsor, _box, false);
        emit ReinvestBoxEvent(_sponsor, sponsorResult, _user, _box, false);
        modifySmartTeamSponsor(sponsorResult, _sponsor, _box);
    }

    function applyDistribution(address _from, address _to, uint8 _box, bool _isSmartDirect) private {
        (address receiver, bool haveMissed) = getReceiver(_from, _to, _box, _isSmartDirect, false);
        uint box70Ptg = percentage(boxesValues[_box], 70);
        uint boxSystemAmount = boxesValues[_box] - box70Ptg;
        uint lotteryAmount = percentage(boxSystemAmount, 70);
        uint restAmount = boxSystemAmount - lotteryAmount;
        uint externalAmount = percentage(restAmount, 69);
        uint externalFeeAmount = percentage(restAmount, 1);
        if(!address(uint160(receiver)).send(box70Ptg))
            address(uint160(receiver)).transfer(box70Ptg);
        if(!externalAddress.send(externalAmount))
            externalAddress.transfer(externalAmount);
        if(!externalFeeAddress.send(externalFeeAmount))
            externalFeeAddress.transfer(externalFeeAmount);
        lottery.addToRaffle.value(lotteryAmount)();
        careerPlan.addToBalance.value(restAmount - externalAmount - externalFeeAmount)();
        if (haveMissed)
            emit SentExtraEvent(_from, receiver, _box, _isSmartDirect);
    }

    function percentage(uint amount, uint8 ptg) internal pure returns(uint) {
        return amount * ptg / 100;
    }

    function getReceiver(address _from, address _to, uint8 _box, bool _isSmartDirect, bool _haveMissed) private  returns(address, bool) {
        bool blocked;
        address sponsor;
        if (_isSmartDirect) {
            SmartDirectBox memory directBoxData = users[_to].directBoxes[_box];
            blocked = directBoxData.inactive;
            sponsor = directBoxData.currentSponsor;
        } else {
            SmartTeamBox memory teamBoxData = users[_to].teamBoxes[_box];
            blocked = teamBoxData.inactive;
            sponsor = teamBoxData.currentSponsor;
        }
        if (!blocked) return (_to, _haveMissed);
        emit MissedEvent(_from, _to, _box, _isSmartDirect);
        return getReceiver(_from, sponsor, _box, _isSmartDirect, true);
    }

    function userSmartDirectBoxInfo(address _user, uint8 _box) public view returns(bool, bool, uint, address[] memory, address) {
        SmartDirectBox memory data = users[_user].directBoxes[_box];
        return (data.purchased, data.inactive, data.reinvests,
        data.childs, data.currentSponsor);
    }

    function userSmartTeamBoxInfo(address _user, uint8 _box) public view returns(bool, bool, uint, address, address[] memory, address[] memory, address) {
        SmartTeamBox memory data = users[_user].teamBoxes[_box];
        return (data.purchased, data.inactive, data.reinvests, data.closedAddr,
        data.firstLevelChilds, data.secondLevelChilds, data.currentSponsor);
    }

    function isValidUser(address _user) public view returns (bool) {
        return (users[_user].id != 0);
    }
}
