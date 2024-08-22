// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Lottery} from "../src/Lottery.sol";
import {Script, console} from "forge-std/Script.sol";

contract DeployLottery is Script {
    Lottery public lottery;

    function run() public {
        vm.startBroadcast();

        lottery = new Lottery();

        vm.stopBroadcast();

        console.log("Lottery deployed at:", address(lottery));
    }
}
