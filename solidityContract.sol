//SPDX-License-Identifier: GPL-2.0-only OR MIT
pragma solidity ^0.7.4;

contract Parser {
    
    bytes public buf;
    
    constructor(byte _type, byte _subType) {
        pushByte(_type);
        pushByte(_subType);
    }
    
    function pushByte(byte value) public returns (Parser){
        buf.push(value);
        return this;
    }
    
    function pushShort(int16 value) public returns (Parser) {
        bytes memory valueBytes = abi.encodePacked(value);
        addBytesToBuf(valueBytes);
        return this;
    }
    
    function pushInt(int32 value) public returns (Parser) {
        bytes memory valueBytes = abi.encodePacked(value);
        addBytesToBuf(valueBytes);
        return this;
    }
    
    function pushLong(int64 value) public returns (Parser) {
        bytes memory valueBytes = abi.encodePacked(value);
        addBytesToBuf(valueBytes);
        return this;
    }
    
    function pushBytes(bytes memory value) public returns (Parser) {
        bytes memory valueLengthBytes = abi.encodePacked(uint32(value.length));
        addBytesToBuf(valueLengthBytes);
        addBytesToBuf(value);
        return this;
    }
    
    function addBytesToBuf(bytes memory valueBytes) internal {
        for(uint i = 0; i < valueBytes.length; i++){
            pushByte(valueBytes[i]);
        }
    }
}
