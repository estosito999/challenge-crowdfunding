// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; // Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./FundingRecipient.sol";

contract CrowdFund {
    /////////////////
    /// Errors //////
    /////////////////

    error NotOpenToWithdraw();
    error WithdrawTransferFailed(address to, uint256 amount);
    error TooEarly(uint256 deadline, uint256 currentTimestamp);

    //////////////////////
    /// State Variables //
    //////////////////////
    
    FundingRecipient public fundingRecipient;
    mapping(address => uint256) public balances;
    bool public openToWithdraw; // por defecto es false
    uint256 public deadline = block.timestamp + 2 hours;
    uint256 public constant threshold = 1 ether;


    ////////////////
    /// Events /////
    ////////////////

    event Contribution(address, uint256);

    ///////////////////
    /// Modifiers /////
    ///////////////////

    modifier notCompleted() {
        _;
    }

    ///////////////////
    /// Constructor ///
    ///////////////////

    constructor(address fundingRecipientAddress) {
        fundingRecipient = FundingRecipient(fundingRecipientAddress);
    }

    ///////////////////
    /// Functions /////
    ///////////////////

    function contribute() public payable {
        balances[msg.sender] += msg.value;
        emit Contribution(msg.sender, msg.value);
    }

    function withdraw() public {
        if (!openToWithdraw) revert NotOpenToWithdraw();

        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: balance}("");
        if (!success) revert WithdrawTransferFailed(msg.sender, balance);
    }

    function execute() public {
        if (block.timestamp <= deadline) revert TooEarly(deadline, block.timestamp);

        if (address(this).balance >= threshold) {
            fundingRecipient.complete{value: address(this).balance}();
        } else {
            openToWithdraw = true;
        }
    }

    fallback() external payable {
        contribute();
    }

    ////////////////////////
    /// View Functions /////
    ////////////////////////

    function timeLeft() public view returns (uint256) {
        return deadline > block.timestamp ? deadline - block.timestamp : 0;
    }
}
