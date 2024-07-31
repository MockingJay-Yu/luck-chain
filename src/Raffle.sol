// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    VRFConsumerBaseV2Plus,
    IVRFCoordinatorV2Plus
} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Raffle Contract
 * @author MockingJay-Yu
 * @notice This contract is for creating a raffle
 * @dev Implements Chainlink VRFv2_5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle_NotEnoughETHSent();
    error Raffle_TansferFail();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    enum RaffleState {
        OPEN, //0
        CALCULATING //1

    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    IVRFCoordinatorV2Plus private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    event EnterRaffle(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequerstedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughETHSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));

        emit EnterRaffle(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Automation nodes call
     * to see if it's time to perform an upkeep
     * The following should be true for this to return true
     * 1. The time interval has passed between raffle runs
     * 2. The raffle is in the open state
     * 3. The contract has ETH
     * 4. The subscription is funded with LINK
     */
    function checkUpkeep(bytes memory /* checkData */ ) public view returns (bool upkeepNeeded, bytes memory) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane, //gas lane
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
        emit RequerstedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256, /*_requestId*/ uint256[] calldata _randomWords) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success,) = s_recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TansferFail();
        }
        emit WinnerPicked(winner);
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
