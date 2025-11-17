// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Simple Crowdfunding
 * @dev A basic crowdfunding smart contract for blockchain-based fundraising
 */
contract Project {
    address public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public totalFundsRaised;
    bool public goalReached;
    bool public campaignClosed;
    
    mapping(address => uint256) public contributions;
    address[] public contributors;
    
    event ContributionReceived(address contributor, uint256 amount);
    event GoalReached(uint256 totalAmount);
    event FundsWithdrawn(address owner, uint256 amount);
    event RefundIssued(address contributor, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier campaignActive() {
        require(block.timestamp < deadline, "Campaign has ended");
        require(!campaignClosed, "Campaign is closed");
        _;
    }
    
    modifier campaignEnded() {
        require(block.timestamp >= deadline, "Campaign is still active");
        _;
    }
    
    /**
     * @dev Constructor to initialize the crowdfunding campaign
     * @param _fundingGoal The target amount to raise (in wei)
     * @param _durationInDays Campaign duration in days
     */
    constructor(uint256 _fundingGoal, uint256 _durationInDays) {
        owner = msg.sender;
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        goalReached = false;
        campaignClosed = false;
    }
    
    /**
     * @dev Core Function 1: Contribute funds to the campaign
     * Anyone can contribute ETH to the campaign before the deadline
     */
    function contribute() public payable campaignActive {
        require(msg.value > 0, "Contribution must be greater than 0");
        
        // Track new contributors
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        
        contributions[msg.sender] += msg.value;
        totalFundsRaised += msg.value;
        
        emit ContributionReceived(msg.sender, msg.value);
        
        // Check if goal is reached
        if (totalFundsRaised >= fundingGoal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalFundsRaised);
        }
    }
    
    /**
     * @dev Core Function 2: Withdraw funds (only if goal reached)
     * Owner can withdraw funds only if the funding goal was reached
     */
    function withdrawFunds() public onlyOwner campaignEnded {
        require(goalReached, "Funding goal not reached");
        require(!campaignClosed, "Funds already withdrawn");
        
        campaignClosed = true;
        uint256 amount = address(this).balance;
        
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    /**
     * @dev Core Function 3: Refund contributors (if goal not reached)
     * Contributors can claim refunds if the campaign ended without reaching the goal
     */
    function claimRefund() public campaignEnded {
        require(!goalReached, "Goal was reached, no refunds available");
        require(contributions[msg.sender] > 0, "No contribution to refund");
        
        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "Refund transfer failed");
        
        emit RefundIssued(msg.sender, refundAmount);
    }
    
    /**
     * @dev Get campaign details
     * @return campaignOwner Address of the campaign creator
     * @return goal The funding goal amount
     * @return raised Total funds raised so far
     * @return timeLeft Remaining time in seconds (0 if ended)
     * @return isGoalReached Whether the funding goal was reached
     * @return isClosed Whether the campaign is closed
     * @return contributorCount Number of unique contributors
     */
    function getCampaignDetails() public view returns (
        address campaignOwner,
        uint256 goal,
        uint256 raised,
        uint256 timeLeft,
        bool isGoalReached,
        bool isClosed,
        uint256 contributorCount
    ) {
        uint256 remaining = 0;
        if (block.timestamp < deadline) {
            remaining = deadline - block.timestamp;
        }
        
        return (
            owner,
            fundingGoal,
            totalFundsRaised,
            remaining,
            goalReached,
            campaignClosed,
            contributors.length
        );
    }
    
    /**
     * @dev Get contribution amount for a specific address
     * @param _contributor Address of the contributor
     * @return contributionAmount Amount contributed by the address
     */
    function getContribution(address _contributor) public view returns (uint256 contributionAmount) {
        return contributions[_contributor];
    }
    
    /**
     * @dev Fallback function to accept ETH
     */
    receive() external payable {
        contribute();
    }
}
