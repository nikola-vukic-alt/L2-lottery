// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Lottery {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum LotteryState {
        OPEN,
        CLOSED
    }

    uint256 public constant PARITICIPATION_FEE = 1e16;

    LotteryState private s_state;
    EnumerableSet.AddressSet private s_players;
    uint256 s_startTime;

    event NewPlayerEntered(address playerAddress);
    event PlayerWithdrew(address playerAddress);
    event WinnerPicked(address winnerAddress, uint256 winningAmount);

    error PlayerAlreadyEntered();
    error NotPlayer();
    error IncorrectParticipationFee(uint256 required, uint256 given);
    error LotteryClosed();
    error TransferFailed();
    error NotEnoughTimePassed();

    modifier onlyWhenStateIsOpen() {
        if (_shouldCloseLottery()) s_state = LotteryState.CLOSED;
        if (LotteryState.CLOSED == s_state) revert LotteryClosed();
        _;
    }

    constructor() {
        s_startTime = block.timestamp;
        s_state = LotteryState.OPEN;
    }

    function enterLottery() external payable onlyWhenStateIsOpen {
        if (msg.value != PARITICIPATION_FEE)
            revert IncorrectParticipationFee(PARITICIPATION_FEE, msg.value);

        if (false == s_players.add(msg.sender)) revert PlayerAlreadyEntered();

        emit NewPlayerEntered(msg.sender);
    }

    function withdrawFromLottery() external onlyWhenStateIsOpen {
        if (false == s_players.contains(msg.sender)) revert NotPlayer();

        (bool success, ) = msg.sender.call{value: PARITICIPATION_FEE}("");
        if (false == success) revert TransferFailed();

        // Reentrancy vulnerability
        s_players.remove(msg.sender);

        emit PlayerWithdrew(msg.sender);
    }

    function drawWinner() external {
        if (LotteryState.OPEN == s_state && false == _shouldCloseLottery())
            revert NotEnoughTimePassed();

        s_state = LotteryState.CLOSED;

        uint256 playerCount = s_players.length();

        // Timestamp dependance vulnerability
        uint256 winnerIdx = block.timestamp % playerCount;

        address winner = s_players.at(winnerIdx);
        uint256 prize = address(this).balance;

        (bool success, ) = winner.call{value: prize}("");
        if (false == success) revert TransferFailed();

        // DoS vulnerability
        for (uint256 i = 0; i < playerCount; i++) {
            s_players.remove(s_players.at(0));
        }

        s_state = LotteryState.OPEN;
        s_startTime = block.timestamp;

        emit WinnerPicked(winner, prize);
    }

    function getState() external view returns (uint256) {
        return uint256(s_state);
    }

    function _shouldCloseLottery() private view returns (bool) {
        return
            block.timestamp >= s_startTime + 7 days &&
            s_state == LotteryState.OPEN;
    }
}
