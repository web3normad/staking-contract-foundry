// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Coin} from "../src/Coin.sol";
import {StakingPool} from "../src/Staking.sol";
import {console} from "forge-std/console.sol";

contract DeployStaking is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Coin coin = new Coin(address(this)); 
        address coinAddress = address(coin);

        StakingPool stakingPool = new StakingPool(coinAddress);

        console.log("Coin Address: ", coinAddress);
        console.log("StakingPool Address: ", address(stakingPool));

        vm.stopBroadcast();
    }
}
