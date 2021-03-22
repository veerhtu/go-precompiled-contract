//SPDX-License-Identifier: GPL-2.0-only OR MIT
pragma solidity ^0.7.4;

library IcteLib {
    function DbgLg(string memory l) public {}
    function StSts(bytes memory k, byte s) public returns (byte) {}
    function GtSts(bytes memory k) public returns (byte) {}
    function RplcVl(bytes memory k, bytes memory v) public returns (bytes memory) {}
    function AdVl(bytes memory k, bytes memory v) public returns (bytes memory) {}
    function GtVl(bytes memory k) public returns (bytes memory) {}
    function RmVl(bytes memory k) public returns (bytes memory) {}
}

contract NewContract {
    byte constant TYPE_LAST_RESERVED_CRYPTO = byte(0x00);
    byte constant TYPE_RESERVED_NAME = byte(0x01);
    byte constant TYPE_TOKEN_STAGE = byte(0x20);
    byte constant TYPE_TOKEN_STATE = byte(0x21);
    byte constant TYPE_TOKEN_NAME = byte(0x22);
    byte constant TYPE_TOKEN_DESC = byte(0x23);
    Crypto immutable crypto;
    
    constructor() {
        crypto = new Crypto(this);
    }
    
    struct ClientActiveCryptos {
        mapping(uint => int32) indexToToken;
        mapping(int32 => uint) tokenToIndex;
    }

    enum Stage  {Dev,Test,Prod}
    enum State  {Disabled,Enabled,Halted}
    enum Access {Unknown,WhiteList,BlackList,Developer,Admin,Owner}

    /********************************************************************
    *   CRYPTO OPERATIONS
    ********************************************************************/
    
    function getBalance(int32 cryptoId, address account)
    cryptoExists(cryptoId)
    public
    returns (int64)
    {
        return crypto.balance(cryptoId, account);
    }
    
    function mint(int32 cryptoId, address account, int64 qty)
    cryptoExists(cryptoId)
    public
    {
        return crypto.mint(cryptoId, account, qty);
    }
    
    function burn(int32 cryptoId, address account, int64 qty)
    cryptoExists(cryptoId)
    public
    {
        return crypto.burn(cryptoId, account, qty);
    }

    /********************************************************************
    *   MANAGER OPERATIONS
    ********************************************************************/

    function registerNewCrypto(bytes26 cryptoName, string memory cryptoDescription)
    external
    returns (int32)
    {
        IcteLib.DbgLg(string(abi.encodePacked("Creating crypto: ", cryptoName, " - ", cryptoDescription)));
        int32 registered = isNameRegistered(abi.encodePacked(cryptoName));
        if(registered >= 0){
            IcteLib.DbgLg("Invalid crypto name -- ALREADY EXISTS");
            return registered;
        }

        int32 cryptoId = getLastReservedId() + 1;
        
        bytes memory keySTAGE = abi.encodePacked(TYPE_TOKEN_STAGE, cryptoId);
        bytes memory valueSTAGE = abi.encode(Stage.Dev);
        IcteLib.RplcVl(keySTAGE, valueSTAGE);
        bytes memory keySTATE = abi.encodePacked(TYPE_TOKEN_STATE, cryptoId);
        bytes memory valueSTATE = abi.encode(State.Disabled);
        IcteLib.RplcVl(keySTATE, valueSTATE);
        bytes memory keyNAME = abi.encodePacked(TYPE_TOKEN_NAME, cryptoId);
        bytes memory valueNAME = abi.encodePacked(cryptoName);
        IcteLib.RplcVl(keyNAME, valueNAME);
        bytes memory keyDESC = abi.encodePacked(TYPE_TOKEN_DESC, cryptoId);
        bytes memory valueDESC = abi.encode(cryptoDescription);
        IcteLib.RplcVl(keyDESC, valueDESC);
        bytes memory keyRESERVEDNAME = abi.encodePacked(TYPE_RESERVED_NAME, cryptoName);
        bytes memory valueRESERVEDNAME = abi.encode(cryptoId);
        IcteLib.RplcVl(keyRESERVEDNAME, valueRESERVEDNAME);
        
        
        bytes memory keyRESERVED = abi.encodePacked(TYPE_LAST_RESERVED_CRYPTO);
        bytes memory valueRESERVED = abi.encode(cryptoId);
        IcteLib.RplcVl(keyRESERVED, valueRESERVED);
        return cryptoId;
    }

    function setStage(int32 cryptoId, Stage _stage)
    cryptoExists(cryptoId)
    public
    {
        Stage stage = crypto.getStage(cryptoId);
        require(_stage != stage);
        require(Stage.Prod != stage);
        crypto.setStage(cryptoId, _stage, msg.sender);
    }

    function setState(int32 cryptoId, State _state)
    cryptoExists(cryptoId)
    public
    {
        crypto.setState(cryptoId, _state, msg.sender);
    }
    
    function AddBlackList(int32 id, address account) public {
        crypto.AddBlackList(id, msg.sender, account);
    }
    function AddWhiteList(int32 id, address account) public {
        crypto.AddWhiteList(id, msg.sender, account);
    }
    function AddDeveloper(int32 id, address account) public {
        crypto.AddDeveloper(id, msg.sender, account);
    }
    function AddAdmin(int32 id, address account) public {
        crypto.AddAdmin(id, msg.sender, account);
    }
    function AddOwner(int32 id, address account) public {
        crypto.AddOwner(id, msg.sender, account);
    }
    function RemoveBlackList(int32 id, address account) public {
        crypto.RemoveBlackList(id, msg.sender, account);
    }
    function RemoveWhiteList(int32 id, address account) public {
        crypto.RemoveWhiteList(id, msg.sender, account);
    }
    function RemoveDeveloper(int32 id, address account) public {
        crypto.RemoveDeveloper(id, msg.sender, account);
    }
    function RemoveAdmin(int32 id, address account) public {
        crypto.RemoveAdmin(id, msg.sender, account);
    }
    function RemoveOwner(int32 id) public {
        crypto.RemoveOwner(id, msg.sender);
    }

    /********************************************************************
    *   INTERNAL FUNCTIONS CANNOT BE EXECUTED
    ********************************************************************/
    
    function getLastReservedId() internal returns (int32) {
        bytes memory key = abi.encodePacked(TYPE_LAST_RESERVED_CRYPTO);
        bytes memory saved = IcteLib.GtVl(key);
        return(abi.decode(saved, (int32)));
    }
    
    function isNameRegistered(bytes memory name) internal returns (int32) {
        bytes memory key = abi.encodePacked(TYPE_RESERVED_NAME, name);
        bytes memory saved = IcteLib.GtVl(key);
        if(saved.length == 0){
            return -1;
        } else {
            return abi.decode(saved, (int32));
        }
    }

    modifier cryptoExists(int32 cryptoId)
    {
        require(cryptoId < getLastReservedId());
        require(crypto.getState(cryptoId) != State.Disabled);
        _;
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
    
    function canModifyBool(int32 cryptoId, Access level, bool requiresNonProd) cryptoExists(cryptoId) public returns (bool) {
        if(requiresNonProd && Stage.Prod == crypto.getStage(cryptoId)) {
            return false;
        }
        Access accessLevel = crypto.GetAccess(cryptoId, msg.sender);
        if(Access(accessLevel) == Access.BlackList){
            return false;
        }
        return(Access(accessLevel) >= level);
    }

    modifier canModify(int32 cryptoId, Access level, bool requiresNonProd) {
        require(canModifyBool(cryptoId, level, requiresNonProd));
        _;
    }
}

/**
 * @title Crypto
 * @dev Mint, Transfer, and Burn coins
 */
contract Crypto {
    
    NewContract immutable manager;
    byte constant TYPE_CLIENT_BALANCE = byte(0x10);
    byte constant TYPE_CLIENT_NONCE = byte(0x11);
    byte constant TYPE_CLIENT_ACCESS = byte(0x12);
    byte constant TYPE_TOKEN_STAGE = byte(0x20);
    byte constant TYPE_TOKEN_STATE = byte(0x21);
    byte constant TYPE_TOKEN_NAME = byte(0x22);
    byte constant TYPE_TOKEN_DESC = byte(0x23);
    
    constructor(
        NewContract cryptoManager
        )
    {
        manager = cryptoManager;
    }
    
    function balance(int32 id, address _account) public byManager() returns (int64) {
        bytes memory key = abi.encodePacked(TYPE_CLIENT_BALANCE, id, _account);
        bytes memory value = IcteLib.GtVl(key);
        return abi.decode(value, (int64));
    }
    
    function setStage(int32 id, NewContract.Stage _stage, address sender) public canModify(id, sender, NewContract.Access.Admin, true) {
        bytes memory key = abi.encodePacked(TYPE_TOKEN_STAGE, id);
        bytes memory value = abi.encode(_stage);
        IcteLib.RplcVl(key, value);
    }
    
    function getStage(int32 id) public byManager() returns (NewContract.Stage stage) {
        bytes memory key = abi.encodePacked(TYPE_TOKEN_STAGE, id);
        bytes memory value = IcteLib.GtVl(key);
        stage = abi.decode(value, (NewContract.Stage));
    }
    
    function setState(int32 id, NewContract.State _state, address sender) public canModify(id, sender, NewContract.Access.Admin, false) {
        bytes memory key = abi.encodePacked(TYPE_TOKEN_STATE, id);
        bytes memory value = abi.encode(_state);
        IcteLib.RplcVl(key, value);
    }
    
    function getState(int32 id) public byManager() returns (NewContract.State state) {
        bytes memory key = abi.encodePacked(TYPE_TOKEN_STATE, id);
        bytes memory value = IcteLib.GtVl(key);
        state = abi.decode(value, (NewContract.State));
    }
    
    
    function setName(int32 id, string memory _name) internal {
        bytes memory key = abi.encodePacked(TYPE_TOKEN_NAME, id);
        bytes memory value = abi.encode(_name);
        IcteLib.RplcVl(key, value);
    }
    
    function getName(int32 id) public byManager() returns (string memory name) {
        bytes memory key = abi.encodePacked(TYPE_TOKEN_NAME, id);
        bytes memory value = IcteLib.GtVl(key);
        name = abi.decode(value, (string));
    }

    function mint(int32 id, address _account, int64 qty) public byManager {
        bytes memory key = abi.encodePacked(TYPE_CLIENT_BALANCE, id, _account);
        bytes memory currentBal = IcteLib.GtVl(key);
        int64 currentBalLong = abi.decode(currentBal, (int64));
        bytes memory value = abi.encode(currentBalLong + qty);
        IcteLib.RplcVl(key, value);
    }

    function burn(int32 id, address _account, int64 qty) public byManager {
        bytes memory key = abi.encodePacked(TYPE_CLIENT_BALANCE, id, _account);
        bytes memory currentBal = IcteLib.GtVl(key);
        int64 currentBalLong = abi.decode(currentBal, (int64));
        require(currentBalLong >= qty);
        bytes memory value = abi.encode(currentBalLong - qty);
        IcteLib.RplcVl(key, value);
    }
    
    function AddBlackList(int32 id, address sender, address account) public canModify(id, sender, NewContract.Access.Admin, false) {
        AddAccess(id, account, NewContract.Access.BlackList);
    }
    function AddWhiteList(int32 id, address sender, address account) public canModify(id, sender, NewContract.Access.Admin, false) {
        AddAccess(id, account, NewContract.Access.WhiteList);
    }
    function AddDeveloper(int32 id, address sender, address account) public canModify(id, sender, NewContract.Access.Admin, false) {
        AddAccess(id, account, NewContract.Access.Developer);
    }
    function AddAdmin(int32 id, address sender, address account) public canModify(id, sender, NewContract.Access.Admin, false) {
        AddAccess(id, account, NewContract.Access.Admin);
    }
    function AddOwner(int32 id, address sender, address account) public canModify(id, sender, NewContract.Access.Owner, false) {
        AddAccess(id, account, NewContract.Access.Owner);
    }
    function RemoveBlackList(int32 id, address sender, address account) public canModify(id, sender, NewContract.Access.Admin, false) {
        RemoveAccess(id, account, NewContract.Access.BlackList);
    }
    function RemoveWhiteList(int32 id, address sender, address account) public canModify(id, sender, NewContract.Access.Admin, false) {
        RemoveAccess(id, account, NewContract.Access.WhiteList);
    }
    function RemoveDeveloper(int32 id, address sender, address account) public canModify(id, sender, NewContract.Access.Admin, false) {
        RemoveAccess(id, account, NewContract.Access.Developer);
    }
    function RemoveAdmin(int32 id, address sender, address account) public canModify(id, sender, NewContract.Access.Owner, false) {
        RemoveAccess(id, account, NewContract.Access.Admin);
    }
    function RemoveOwner(int32 id, address sender) public canModify(id, sender, NewContract.Access.Owner, false) {
        RemoveAccess(id, sender, NewContract.Access.Owner);
    }
    
    function AddAccess(int32 id, address account, NewContract.Access access) internal {
        bytes memory key = abi.encodePacked(TYPE_CLIENT_ACCESS, id, account);
        bytes memory value = abi.encode(access);
        IcteLib.RplcVl(key, value);
    }
    
    function RemoveAccess(int32 id, address account, NewContract.Access access) internal {
        bytes memory key = abi.encodePacked(TYPE_CLIENT_ACCESS, id, account);
        bytes memory currentBal = IcteLib.GtVl(key);
        NewContract.Access currentAccess = abi.decode(currentBal, (NewContract.Access));
        require(currentAccess == access);
        IcteLib.RmVl(key);
    }
    
    function GetAccess(int32 id, address account) public returns (NewContract.Access access) {
        bytes memory key = abi.encodePacked(TYPE_CLIENT_ACCESS, id, account);
        bytes memory value = IcteLib.GtVl(key);
        access = abi.decode(value, (NewContract.Access));
    }
    function canModifyBool(int32 id, address sender, NewContract.Access level, bool requiresNonProd) public returns (bool) {
        require(msg.sender == address(manager));
        NewContract.Stage stage = getStage(id);
        if(requiresNonProd && NewContract.Stage.Prod == stage) {
            return false;
        }
        NewContract.Access accessLevel = GetAccess(id, sender);
        if(accessLevel == NewContract.Access.BlackList){
            return false;
        }
        return(accessLevel >= level);
    }

    modifier canModify(int32 id, address sender, NewContract.Access level, bool requiresNonProd) {
        require(address(manager) == msg.sender);
        require(canModifyBool(id, sender, level, requiresNonProd));
        _;
    }
    
    modifier byManager() {
        require(address(manager) == msg.sender);
        _;
    }
}
