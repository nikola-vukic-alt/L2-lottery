// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract LotteryTest is Test {
    uint256 public constant PARITICIPATION_FEE = 1e16;

    address[] players = [
        makeAddr("p1"),
        makeAddr("p2"),
        makeAddr("p3"),
        makeAddr("p4"),
        makeAddr("p5")
    ];

    Lottery public lottery;

    function setUp() public {
        lottery = new Lottery();
        for (uint256 i = 0; i < 5; i++) vm.deal(players[i], PARITICIPATION_FEE);
    }

    function test_LotteryStartsInOpenState() public view {
        assertEq(lottery.getState(), uint256(Lottery.LotteryState.OPEN));
    }

    function test_EnterLotteyIncreasesContractBalance() public {
        uint256 oldBalance = address(lottery).balance;

        vm.prank(players[0]);
        lottery.enterLottery{value: PARITICIPATION_FEE}();

        uint256 newBalance = address(lottery).balance;

        assertEq(oldBalance + PARITICIPATION_FEE, newBalance);
    }

    //////////////////////////////
    //       Validations        //
    //////////////////////////////

    function test_EnterLotteryRevertsIfIncorrectParticipationFeeIsSent()
        public
    {
        vm.prank(players[0]);

        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.IncorrectParticipationFee.selector,
                PARITICIPATION_FEE,
                PARITICIPATION_FEE - 1
            )
        );

        lottery.enterLottery{value: PARITICIPATION_FEE - 1}();
    }

    function test_EnterLotteryRevertsIfSenderIsAlreadyPlayer() public {
        vm.deal(players[0], 2 * PARITICIPATION_FEE);

        vm.startPrank(players[0]);
        lottery.enterLottery{value: PARITICIPATION_FEE}();

        vm.expectRevert(Lottery.PlayerAlreadyEntered.selector);
        lottery.enterLottery{value: PARITICIPATION_FEE}();

        vm.stopPrank();
    }

    //////////////////////////////
    //          Events          //
    //////////////////////////////

    function test_EnterLotteryEmitsEvent() public {
        vm.expectEmit();
        emit Lottery.NewPlayerEntered(players[0]);

        vm.prank(players[0]);
        lottery.enterLottery{value: PARITICIPATION_FEE}();
    }
}
