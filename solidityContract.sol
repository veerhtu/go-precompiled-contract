//SPDX-License-Identifier: GPL-2.0-only OR MIT
pragma solidity ^0.7.4;

library IcteLib {
    function DbgLg(string memory l) public {}
}

contract NewContract {

    struct SkillStruct {
        int32 id;
        State state;
        Stage stage;
        bytes26 skillName;
        Skill skill;
    }

    enum Stage {
        Dev,
        Test,
        Prod
    }

    enum State {
        Disabled,
        Active,
        Halted
    }

    enum Access {
        Unknown,
        WhiteList,
        BlackList,
        Developer,
        Admin,
        Coowner,
        Owner
    }

    SkillStruct[] private SkillList;
    mapping(bytes26 => int32) private registeredNames;


    /********************************************************************
    *   SKILL OPERATIONS
    ********************************************************************/
    function getBalance(int32 skillId)
    public
    view
    returns (uint)
    {
        return getBalance(skillId, msg.sender);
    }
    
    function mint(int32 skillId, uint256 qty)
    public
    canModify(skillId, Access.Coowner, false)
    {
        Skill skill = getSkill(skillId);
        skill.mint(qty);
    }
    
    function transferTo(int32 skillId, uint256 qty, address to)
    public
    canModify(skillId, Access.Admin, false)
    {
        Skill skill = getSkill(skillId);
        skill.transferTo(qty, to);
    }

    function transferFrom(int32 skillId, uint256 qty, address from)
    public
    canModify(skillId, Access.Admin, false)
    {
        Skill skill = getSkill(skillId);
        skill.transferFrom(qty, from);
    }
    
    /********************************************************************
    *   LIST SKILL OPERATIONS
    ********************************************************************/

    function listSkills()
    public
    view
    returns (bytes32[] memory result)
    {
        result = new bytes32[](SkillList.length);
        uint index = 0;
        for (uint i = 0; i < SkillList.length; i++) {
            SkillStruct memory tStruct = SkillList[i];
            result[index] = toBytes32(abi.encodePacked(
                    tStruct.id,
                    tStruct.stage,
                    tStruct.state,
                    tStruct.skillName
                ));
            index++;
        }

        if (index < result.length) {
            uint delta = result.length - index;
            assembly {
                mstore(result, sub(mload(result), delta))
            }
        }

    }

    function getActiveSkills(address user)
    public
    view
    returns (bytes12[] memory result)
    {
        result = new bytes12[](SkillList.length);
        uint index = 0;
        for (uint i = 0; i < SkillList.length; i++) {
            SkillStruct memory tStruct = SkillList[i];
            uint64 balance = uint64(tStruct.skill.balance(user));
            if(balance > 0) {
                result[index] = toBytes12(abi.encodePacked(
                    tStruct.id,
                    balance
                ));
                index++;
            }
        }

        if (index < result.length) {
            uint delta = result.length - index;
            assembly {
                mstore(result, sub(mload(result), delta))
            }
        }
    }

    /********************************************************************
    *   MANAGER OPERATIONS
    ********************************************************************/

    function registerNewSkill(bytes26 skillName)
    external
    returns (int32)
    {
        IcteLib.DbgLg(string(abi.encodePacked("registering skill: ", skillName)));
        if(registeredNames[skillName] != 0){
            IcteLib.DbgLg("Invalid skill name");
        }
        require(registeredNames[skillName] == 0);

        int32 skillId = int32(SkillList.length);
        IcteLib.DbgLg(string(abi.encodePacked("Skill to ID: ", skillId)));
        
        Skill skill = new Skill();
        
        SkillStruct memory tStruct = SkillStruct(
            skillId,
            State.Active,
            Stage.Prod,
            skillName,
            skill
        );

        SkillList.push(tStruct);
        registeredNames[skillName] = tStruct.id + 1;
        return tStruct.id;
    }

    function setStage(int32 skillId, Stage _stage)
    public
    canModify(skillId, Access.Admin, false)
    {
        SkillStruct memory tStruct = SkillList[uint(skillId)];
        require(_stage != tStruct.stage);
        require(Stage.Prod != tStruct.stage);
        tStruct.stage = _stage;
        SkillList[uint(skillId)] = tStruct;
    }

    function setState(int32 skillId, State _state)
    public
    canModify(skillId, Access.Admin, false)
    {
        SkillStruct memory tStruct = SkillList[uint(skillId)];
        tStruct.state = _state;
        SkillList[uint(skillId)] = tStruct;
    }

    function setTokenName(int32 skillId, bytes26 _skillName)
    public
    canModify(skillId, Access.Owner, false)
    {
        SkillStruct memory tStruct = SkillList[uint(skillId)];
        require(registeredNames[_skillName] == 0);
        bytes26 oldName = tStruct.skillName;
        tStruct.skillName = _skillName;
        delete registeredNames[oldName];
        registeredNames[_skillName] = tStruct.id + 1;

        SkillList[uint(skillId)] = tStruct;
    }
    
    function AddBlackList(int32 skillId, address account) public canModify(skillId, Access.Admin, false) {
        SkillList[uint(skillId)].skill.AddDeveloper(account);
    }
    function AddWhiteList(int32 skillId, address account) public canModify(skillId, Access.Admin, false) {
        SkillList[uint(skillId)].skill.AddWhiteList(account);
    }
    function AddDeveloper(int32 skillId, address account) public canModify(skillId, Access.Admin, false) {
        SkillList[uint(skillId)].skill.AddDeveloper(account);
    }
    function AddAdmin(int32 skillId, address account) public canModify(skillId, Access.Admin, false) {
        SkillList[uint(skillId)].skill.AddAdmin(account);
    }
    function AddOwner(int32 skillId, address account) public canModify(skillId, Access.Owner, false) {
        SkillList[uint(skillId)].skill.AddOwner(account);
    }
    function RemoveBlackList(int32 skillId, address account) public canModify(skillId, Access.Admin, false) {
        SkillList[uint(skillId)].skill.RemoveDeveloper(account);
    }
    function RemoveWhiteList(int32 skillId, address account) public canModify(skillId, Access.Admin, false) {
        SkillList[uint(skillId)].skill.RemoveWhiteList(account);
    }
    function RemoveDeveloper(int32 skillId, address account) public canModify(skillId, Access.Admin, false) {
        SkillList[uint(skillId)].skill.RemoveDeveloper(account);
    }
    function RemoveAdmin(int32 skillId, address account) public canModify(skillId, Access.Owner, false) {
        SkillList[uint(skillId)].skill.RemoveAdmin(account);
    }
    function RemoveOwner(int32 skillId) public canModify(skillId, Access.Owner, false) {
        SkillList[uint(skillId)].skill.RemoveOwner();
    }

    /********************************************************************
    *   INTERNAL FUNCTIONS CANNOT BE EXECUTED
    ********************************************************************/


    function getBalance(int32 tokenId, address account)
    public
    view
    returns (uint)
    {
        Skill t = getSkill(tokenId);
        return t.balance(account);
    }

    function getSkill(int32 skillId)
    internal
    view
    returns (Skill t)
    {
        require(uint(skillId) < SkillList.length);
        SkillStruct memory tStruct = SkillList[uint(skillId)];
        require(tStruct.state == State.Active);
        t = tStruct.skill;
    }

    function toBytes12(bytes memory source)
    internal
    pure
    returns (bytes12 result)
    {
        if (source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 12))
        }
    }

    function toBytes32(bytes memory source)
    internal
    pure
    returns (bytes32 result)
    {
        if (source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function canModifyBool(int32 skillId, Access level, bool requiresNonProd) internal view returns (bool) {
        SkillStruct memory tStruct = SkillList[uint(skillId)];
        if(requiresNonProd && Stage.Prod == tStruct.stage) {
            return false;
        }
        Access accessLevel = SkillList[uint(skillId)].skill.GetAccess(msg.sender);
        if(accessLevel == Access.BlackList){
            return false;
        }
        return(Access(accessLevel) >= level);
    }

    modifier canModify(int32 skillId, Access level, bool requiresNonProd) {
        SkillStruct memory tStruct = SkillList[uint(skillId)];
        require(!(requiresNonProd && Stage.Prod == tStruct.stage));
        Access accessLevel = SkillList[uint(skillId)].skill.GetAccess(msg.sender);
        require(accessLevel != Access.BlackList);
        require(accessLevel >= level);
        _;
    }
}

contract Skill {
    mapping(address => NewContract.Access) private AccessPolicy;

    mapping(address => uint256) private balances;
    
    constructor() {
        AccessPolicy[msg.sender] = NewContract.Access.Owner;
    }
    
    function AddBlackList(address account) public canModify(NewContract.Access.Admin) {
        AccessPolicy[account] = NewContract.Access.BlackList;
    }
    function AddWhiteList(address account) public canModify(NewContract.Access.Admin) {
        AccessPolicy[account] = NewContract.Access.WhiteList;
    }
    function AddDeveloper(address account) public canModify(NewContract.Access.Admin) {
        AccessPolicy[account] = NewContract.Access.Developer;
    }
    function AddAdmin(address account) public canModify(NewContract.Access.Admin) {
        AccessPolicy[account] = NewContract.Access.Admin;
    }
    function AddOwner(address account) public canModify(NewContract.Access.Owner) {
        AccessPolicy[account] = NewContract.Access.Owner;
    }
    function RemoveBlackList(address account) public canModify(NewContract.Access.Admin) {
        delete AccessPolicy[account];
    }
    function RemoveWhiteList(address account) public canModify(NewContract.Access.Admin) {
        delete AccessPolicy[account];
    }
    function RemoveDeveloper(address account) public canModify(NewContract.Access.Admin) {
        delete AccessPolicy[account];
    }
    function RemoveAdmin(address account) public canModify(NewContract.Access.Owner) {
        delete AccessPolicy[account];
    }
    function RemoveOwner() public canModify(NewContract.Access.Owner) {
        delete AccessPolicy[msg.sender];
    }
    
    function GetAccess(address account) public view returns (NewContract.Access) {
        return AccessPolicy[account];
    }

    /**
     * @dev Transfer balance from caller address to receiver address
     * @param receiver address to create coins for
     * @param amount coins to increase receiver balance
     */
    function setBalance(address receiver, uint256 amount) public {
        balances[receiver] += amount;
    }
    
    function mint(uint256 qty) external canModify(NewContract.Access.Coowner) {
        balances[msg.sender] += qty;
    }
    
    function transferTo(uint256 qty, address to) external canModify(NewContract.Access.Admin) {
        require(balances[msg.sender] > qty);
        balances[msg.sender] -= qty;
        balances[to] += qty;
    }
    
    function transferFrom(uint256 qty, address from) external canModify(NewContract.Access.Admin) {
        require(balances[from] > qty);
        balances[from] -= qty;
        balances[msg.sender] += qty;
    }

    /**
     * @dev Get balance for a specific account
     * @param _account account to check balance for
    */
    function balance(address _account) public view returns (uint256) {
        return balances[_account];
    }
    
    modifier canModify(NewContract.Access level) {
        NewContract.Access accessLevel = AccessPolicy[msg.sender];
        require(accessLevel != NewContract.Access.BlackList);
        require(accessLevel >= level);
        _;
    }
}
