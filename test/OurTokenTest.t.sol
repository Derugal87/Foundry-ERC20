// contract OurTokenTest is Test {
//     OurToken public ourToken;
//     DeployOurToken public deployer;

//     address bob = makeAddr("bob");
//     address alice = makeAddr("alice");

//     uint256 public constant STARTING_BALANCE = 100 ether;

//     function setUp() public {
//         deployer = new DeployOurToken();
//         ourToken = deployer.run();

//         vm.prank(msg.sender);
//         ourToken.transfer(bob, STARTING_BALANCE);
//     }

//     function testBobBalance() public view {
//         assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
//     }

//     function testAllowancesWorks() public {
//         uint256 initialAllowance = 1000;

//         // Bob approves Alice to spend tokens on her behalf
//         vm.prank(bob);
//         ourToken.approve(alice, initialAllowance);

//         uint256 transferAmount = 500;

//         vm.prank(alice);
//         ourToken.transferFrom(bob, alice, transferAmount);
//         // ourToken.transfer(bob, initialAllowance);

//         assertEq(ourToken.balanceOf(alice), transferAmount);
//         assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
//     }
// }

// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on her behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);
        // ourToken.transfer(bob, initialAllowance);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testTransfer() public {
        address recipient = address(0x456);
        uint256 amount = 1000;
        uint256 initialBalance = ourToken.balanceOf(msg.sender);

        // Transfer tokens to recipient
        vm.prank(msg.sender);
        ourToken.transfer(recipient, amount);

        // Check if the balance of the recipient is updated
        assertEq(ourToken.balanceOf(recipient), amount);

        // Check if the balance of the sender is reduced
        assertEq(ourToken.balanceOf(msg.sender), initialBalance - amount);
    }

    function testAllowance() public {
        address spender = address(0x123);
        uint256 amount = 1000;

        // Initially, the allowance should be zero
        assertEq(ourToken.allowance(msg.sender, spender), 0);

        // Approve the spender to spend tokens on behalf of the owner
        vm.prank(msg.sender);
        ourToken.approve(spender, amount);

        // Check if the allowance is updated correctly
        assertEq(ourToken.allowance(msg.sender, spender), amount);
    }

    function testTransferFrom() public {
        address spender = address(0x789);
        address recipient = address(0x456);
        uint256 amount = 100 ether;

        // Approve the spender to spend tokens on behalf of the owner
        vm.prank(bob);
        ourToken.approve(spender, amount);
        assertEq(ourToken.allowance(bob, spender), amount);

        // Simulate the spender calling transferFrom
        vm.prank(spender);
        ourToken.transferFrom(bob, recipient, amount);

        // Check if the balance of the recipient is updated
        assertEq(ourToken.balanceOf(recipient), amount);

        // Check if the balance of the sender is reduced
        assertEq(ourToken.balanceOf(msg.sender), ourToken.totalSupply() - amount);

        // Check if the allowance is reduced
        assertEq(ourToken.allowance(msg.sender, spender), 0);
    }

    function testApprove() public {
        address spender = address(0x987);
        uint256 amount = 200 ether;

        // Approve the spender to spend tokens
        vm.prank(msg.sender);
        assertTrue(ourToken.approve(spender, amount));

        // Check if the allowance is updated correctly
        assertEq(ourToken.allowance(msg.sender, spender), amount);

        // Try approving a new amount
        uint256 newAmount = 400;
        vm.prank(msg.sender);
        assertTrue(ourToken.approve(spender, newAmount));

        // Check if the allowance is updated to the new amount
        assertEq(ourToken.allowance(msg.sender, spender), newAmount);
    }

    function testDecreaseAllowance() public {
        address spender = address(0x111);
        uint256 initialAllowance = 500 ether;

        // Approve the spender with an initial allowance
        vm.prank(msg.sender);
        ourToken.approve(spender, initialAllowance);

        // Decrease the allowance
        uint256 newAmount = 100 ether;
        vm.prank(msg.sender);
        assertTrue(ourToken.approve(spender, newAmount));

        // Check if the allowance is updated to the new amount
        assertEq(ourToken.allowance(msg.sender, spender), newAmount);
    }

    function testTransferEvent() public {
        address recipient = address(0x333);
        uint256 amount = 10 ether;

        // Expect the Transfer event to be emitted
        vm.expectEmit(true, true, true, false);
        emit Transfer(msg.sender, recipient, amount);

        // Perform the transfer
        vm.prank(msg.sender);
        ourToken.transfer(recipient, amount);
    }

    function testApprovalEvent() public {
        address spender = address(0x444);
        uint256 amount = 10 ether;

        // Expect the Approval event to be emitted
        vm.expectEmit(true, true, true, false);
        emit Approval(msg.sender, spender, amount);

        // Perform the approval
        vm.prank(msg.sender);
        ourToken.approve(spender, amount);
    }

    function testTransferRevertInsufficientBalance() public {
        address recipient = address(0x555);
        uint256 amount = ourToken.totalSupply() + 1 ether;

        // Expect the transfer to revert due to insufficient balance
        vm.expectRevert();
        vm.prank(msg.sender);
        ourToken.transfer(recipient, amount);
    }

    function testTransferFromRevertInsufficientAllowance() public {
        address spender = address(0x666);
        address recipient = address(0x777);
        uint256 amount = 1000 ether;

        // Try transferring tokens without approving the spender
        vm.prank(spender);
        vm.expectRevert();
        ourToken.transferFrom(msg.sender, recipient, amount);
    }
}
