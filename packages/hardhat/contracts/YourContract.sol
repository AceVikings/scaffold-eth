pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/// @title EgoVerse - CoinFlip
/// @author Ace (EzTools.one)
/// @notice Simple casino contract that allows users to bet against given odds for given token returns
contract YourContract is VRFConsumerBaseV2, ConfirmedOwner {
    VRFCoordinatorV2Interface COORDINATOR;
    IERC20 public token = IERC20(0x2dfb6d18A247dee62BF91857aFB25098F689bf4D);

    struct RequestStatus {
        address user;
        bool fulfilled;
        uint256 paid;
        uint256 code;
    }

    mapping(uint256 => RequestStatus) public s_requests;
    mapping(address => uint[]) public userRequests;
    mapping(address => uint) public userBalance;

    uint userPending;
    uint fees;
    uint64 s_subscriptionId;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    bytes32 keyHash =
        0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;

    uint[4] winRate = [13, 18, 36, 90];
    uint[4] winChance = [65, 50, 25, 10];

    bool paused;
    event ResultEvent(
        address indexed user,
        uint256 amount,
        uint256 randomNumer
    );

    constructor(
        uint64 sub_id
    )
        VRFConsumerBaseV2(0x2eD832Ba664535e5886b75D64C46EB9a228C2610)
        ConfirmedOwner(msg.sender)
    {
        s_subscriptionId = sub_id;
        fees = 0.008 ether;
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2eD832Ba664535e5886b75D64C46EB9a228C2610
        );
    }

    function flip(uint code, uint amount) external payable {
        require(msg.value >= fees, "Fee not paid");
        require(!paused, "Execution paused");
        if (
            amount != 1 ether &&
            amount != 2 ether &&
            amount != 5 ether &&
            amount != 10 ether
        ) {
            revert("Invalid Amount Paid");
        }
        token.transferFrom(msg.sender, address(this), amount);
        uint requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus(msg.sender, false, amount, code);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        settleFlip(_requestId, _randomWords[0]);
    }

    function settleFlip(uint _requestId, uint randomNumer) private {
        uint prize = 0;
        if (randomNumer % 100 < winChance[s_requests[_requestId].code]) {
            prize =
                (winRate[s_requests[_requestId].code] *
                    s_requests[_requestId].paid) /
                10;
            userBalance[s_requests[_requestId].user] += prize;
            userPending += prize;
        }
        emit ResultEvent(msg.sender, prize, randomNumer);
    }

    function claimBalance() external {
        uint balance = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        userPending -= balance;
        token.transfer(msg.sender, balance);
    }

    function setSubId(uint64 subId) external onlyOwner {
        s_subscriptionId = subId;
    }

    function setKeyHash(bytes32 hash) external onlyOwner {
        keyHash = hash;
    }

    function setCallBackGasLimit(uint32 limit) external onlyOwner {
        callbackGasLimit = limit;
    }

    function setCoordinator(address _coordinator) external onlyOwner {
        COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
    }

    function setFees(uint amount) external onlyOwner {
        fees = amount;
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function pause(bool _pause) external onlyOwner {
        paused = _pause;
    }

    function withdraw() external onlyOwner {
        token.transferFrom(
            address(this),
            msg.sender,
            token.balanceOf(address(this)) - userPending
        );
    }

    function withdrawAvax() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }
}
