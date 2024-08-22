// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Lottery} from "../src/Lottery.sol";
import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract EnterLottery is Script {
    uint256 public constant PARITICIPATION_FEE = 0.001 ether;

    function enterLottery(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        Lottery(payable(mostRecentlyDeployed)).enterLottery{
            value: PARITICIPATION_FEE
        }();
        vm.stopBroadcast();

        console.log("New player has entered the lottery.");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Lottery",
            block.chainid
        );
        enterLottery(mostRecentlyDeployed);
    }
}

contract WithdrawFromLottery is Script {
    function withdrawFromLottery(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        Lottery(mostRecentlyDeployed).withdrawFromLottery();
        vm.stopBroadcast();

        console.log("Player has withdrew the lottery.");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Lottery",
            block.chainid
        );
        withdrawFromLottery(mostRecentlyDeployed);
    }
}
