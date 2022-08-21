pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  // maps address to balances 
  mapping ( address => uint256 ) public balances;
  // staking threshhold
  uint256 public constant threshold = 1 ether;
  // staking deadline
  uint256 public deadline = block.timestamp + 30 seconds;
  // staking failed 
  bool public openForWithdrawal = false; 

  // MODIFIERS
  /// Modifier that checks whether the required deadline has passed
  modifier deadlineExpired(bool requireDeadlineExpired) {
    uint256 timeRemaining = timeLeft();
    if (requireDeadlineExpired) {
      require(timeRemaining <= 0, "Deadline has not been passed yet");
    } else {
      require(timeRemaining > 0, "Deadline is already passed");
    }
    _;
  }

  /// Modifier that checks whether the external contract is completed
  modifier stakingNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(completed == false, "Staking period has completed");
    _;
  }

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // TODO: Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  event Stake(address sender, uint256 value); 

  function stake() public payable deadlineExpired(false) stakingNotCompleted {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // TODO: After some `deadline` allow anyone to call an `execute()` function
  //  It should call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

  function execute() public deadlineExpired(true) stakingNotCompleted {
    uint256 contractBalance = address(this).balance;
    if (contractBalance > threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdrawal = true; 
    }
  }

  // TODO: if the `threshold` was not met, allow everyone to call a `withdraw()` function

  function withdraw() public deadlineExpired(true) stakingNotCompleted {

    require(openForWithdrawal, "Not open for withdrawal.");

    uint256 userBalance = balances[msg.sender]; 

    require(userBalance > 0, "User balance is 0"); 

    balances[msg.sender] = 0; 
    
    payable(msg.sender).transfer(userBalance); 

  }

  // TODO: Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0; 
    } else {
      return deadline - block.timestamp;
    }
  }

  // TODO: Add the `receive()` special function that receives eth and calls stake()

  receive() external payable {
    stake();
  }

}
