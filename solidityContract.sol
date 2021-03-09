//SPDX-License-Identifier: GPL-2.0-only OR MIT
pragma solidity ^0.7.4;

library IcteLib {
    function StrtTm(uint8 nt, int64 strtTm, int64 ntrvlTm) public returns (int32) {}
    function StpTm(int32 rdrId) public {}
    function DbgLg(string memory l) public {}
    function FrmtDtTm(int64 tmstmp) public returns (string memory) {}
    function PrgStrg(string memory k) public {}
    function StStrg(bytes memory ts, string memory k) public {}
    function GtI(int32 i, string memory k) public returns (int32) {}
    function GtL(int32 i, string memory k) public returns (int64) {}
}

contract NewContract {
    mapping(int32 => int64) timeOrders;
    
    mapping(string => int32) timers;
    
    uint constant headerLength = 20;
    
    function onMessage(bytes memory goMsg) external {
        uint8 msgType = uint8(goMsg[0]);
        uint8 msgSubType = uint8(goMsg[1]);

        if(msgType == uint8(0x00)){
            if (msgSubType == uint8(0xd0)) { // MsgSubtypeTimestamp
                string memory tmpKey = "tmp";
                IcteLib.StStrg(goMsg, tmpKey);
                int32 rdrId = IcteLib.GtI(2, tmpKey);
                int64 tstmp = IcteLib.GtL(6, tmpKey);
                IcteLib.PrgStrg(tmpKey);
                timeOrders[rdrId] = tstmp;
                IcteLib.DbgLg(string(abi.encodePacked("Timer hit with timestamp = ", IcteLib.FrmtDtTm(tstmp))));
            }
        }
    }
    
    function addTimer(string calldata timerName, uint8 nt, int64 strtTm, int64 ntrvlTm) external {
        int32 orderId = IcteLib.StrtTm(nt, strtTm, ntrvlTm);
        timers[timerName] = orderId;
    }
    
    
    function rmTimer(string calldata timerName) external {
        int32 rdrId = timers[timerName];
        IcteLib.StpTm(rdrId);
        delete timers[timerName];
        delete timeOrders[rdrId];
    }
    
}
