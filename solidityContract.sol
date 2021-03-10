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
        Owner
    }

    //mapping(int32 => mapping(address => Access)) private AccessPolicy;

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
    
    function setBalance(address user, int32 skillId, uint256 bal)
    public
    {
        Skill skill = getSkill(skillId);
        skill.setBalance(user, bal);
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
    }

    function setStage(int32 skillId, Stage _stage)
    public
    {
        SkillStruct memory tStruct = SkillList[uint(skillId)];
        require(_stage != tStruct.stage);
        require(Stage.Prod != tStruct.stage);
        tStruct.stage = _stage;
        SkillList[uint(skillId)] = tStruct;
    }

    function setState(int32 skillId, State _state)
    public
    {
        SkillStruct memory tStruct = SkillList[uint(skillId)];
        tStruct.state = _state;
        SkillList[uint(skillId)] = tStruct;
    }

    function setTokenName(int32 skillId, bytes26 _skillName)
    public
    {
        SkillStruct memory tStruct = SkillList[uint(skillId)];
        require(registeredNames[_skillName] == 0);
        bytes26 oldName = tStruct.skillName;
        tStruct.skillName = _skillName;
        delete registeredNames[oldName];
        registeredNames[_skillName] = tStruct.id + 1;

        SkillList[uint(skillId)] = tStruct;
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
}

contract Skill {

    mapping(address => uint256) private balances;

    /**
     * @dev Transfer balance from caller address to receiver address
     * @param receiver address to create coins for
     * @param amount coins to increase receiver balance
     */
    function setBalance(address receiver, uint256 amount) public {
        balances[receiver] += amount;
    }

    /**
     * @dev Get balance for a specific account
     * @param _account account to check balance for
    */
    function balance(address _account) public view returns (uint256) {
        return balances[_account];
    }
}
