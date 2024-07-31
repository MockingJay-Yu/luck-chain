// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,,,,, uint256 deployerKey) = helperConfig.activeNetWorkConfig();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    function createSubscription(address vrfCoordinator, uint256 deployerKey) public returns (uint256) {
        vm.startBroadcast(deployerKey);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("subId:", subId);
        return subId;
    }

    function run() external returns (uint256) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 30 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint256 subId,, address link, uint256 deployerKey) =
            helperConfig.activeNetWorkConfig();
        fundSubscription(vrfCoordinator, subId, link, deployerKey);
    }

    function fundSubscription(address vrfCoordinator, uint256 subId, address link, uint256 deployerKey) public {
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint256 subId,,, uint256 deployerKey) = helperConfig.activeNetWorkConfig();
        addConsumer(raffle, vrfCoordinator, subId, deployerKey);
    }

    function addConsumer(address raffle, address vrfCoordinator, uint256 subId, uint256 deployerKey) public {
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }
}
