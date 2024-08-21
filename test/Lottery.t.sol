// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "../src/VulnerableLottery.sol";

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

    modifier lotteryEntered() {
        vm.startPrank(players[0]);
        lottery.enterLottery{value: PARITICIPATION_FEE}();
        _;
    }

    function setUp() public {
        lottery = new Lottery();
        for (uint256 i = 0; i < 5; i++) vm.deal(players[i], PARITICIPATION_FEE);
    }

    function test_LotteryStartsInOpenState() public view {
        assertEq(
            uint256(lottery.s_state()),
            uint256(Lottery.LotteryState.OPEN)
        );
    }

    function test_EnterLotteyIncreasesContractBalance() public {
        uint256 oldBalance = address(lottery).balance;

        vm.prank(players[0]);
        lottery.enterLottery{value: PARITICIPATION_FEE}();

        uint256 newBalance = address(lottery).balance;

        assertEq(oldBalance + PARITICIPATION_FEE, newBalance);
    }

    function test_WithdrawFromLotteryIncreasesPlayersBalance()
        public
        lotteryEntered
    {
        uint256 oldBalance = address(players[0]).balance;

        lottery.withdrawFromLottery();
        uint256 newBalance = address(players[0]).balance;

        assertEq(oldBalance + PARITICIPATION_FEE, newBalance);
    }

    function test_DrawWinnerIncreasesWinnersBalance() public {
        uint256 playerCount = 5;
        uint256 prize = playerCount * PARITICIPATION_FEE;

        uint256 oldBalance = address(players[0]).balance;

        for (uint256 i = 0; i < playerCount; i++) {
            vm.prank(players[i]);
            lottery.enterLottery{value: PARITICIPATION_FEE}();
        }

        vm.warp(1725027410);
        lottery.drawWinner();

        uint256 newBalance = address(players[0]).balance;

        assertEq(newBalance, oldBalance + prize - PARITICIPATION_FEE);
    }

    //////////////////////////////
    //       Validations        //
    //////////////////////////////

    function test_EnterLottery_RevertIf_IncorrectParticipationFeeIsSent()
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

    function test_EnterLottery_RevertIf_SenderIsAlreadyPlayer() public {
        vm.deal(players[0], 2 * PARITICIPATION_FEE);

        vm.startPrank(players[0]);
        lottery.enterLottery{value: PARITICIPATION_FEE}();

        vm.expectRevert(Lottery.PlayerAlreadyEntered.selector);
        lottery.enterLottery{value: PARITICIPATION_FEE}();

        vm.stopPrank();
    }

    function test_EnterLottery_RevertIf_LotteryIsClosed() public {
        vm.warp(block.timestamp + 10 days);

        vm.prank(players[0]);
        vm.expectRevert(Lottery.LotteryClosed.selector);

        lottery.enterLottery{value: PARITICIPATION_FEE}();
    }

    function test_WithdrawFromLottery_RevertIf_SenderIsNotPlayer() public {
        vm.prank(players[0]);

        vm.expectRevert(Lottery.NotPlayer.selector);
        lottery.withdrawFromLottery();
    }

    function test_WithdrawFromLottery_RevertIf_LotteryIsClosed()
        public
        lotteryEntered
    {
        vm.warp(block.timestamp + 10 days);

        vm.expectRevert(Lottery.LotteryClosed.selector);
        lottery.withdrawFromLottery();
    }

    function test_DrawWinner_RevertIf_NoPlayersHaveEntered() public {
        vm.expectRevert(Lottery.NoPlayersEntered.selector);
        lottery.drawWinner();
    }

    function test_DrawWinner_RevertIf_NotEnoughTimeHasPassed()
        public
        lotteryEntered
    {
        vm.expectRevert(Lottery.NotEnoughTimePassed.selector);
        lottery.drawWinner();
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

    function test_WithdrawFromLotteryEmitsEvent() public lotteryEntered {
        vm.expectEmit();
        emit Lottery.PlayerWithdrew(players[0]);

        lottery.withdrawFromLottery();
    }

    function test_DrawWinnerEmitsEvent() public lotteryEntered {
        vm.warp(block.timestamp + 10 days);

        vm.expectEmit();
        emit Lottery.WinnerPicked(players[0], PARITICIPATION_FEE);

        lottery.drawWinner();
    }
}
