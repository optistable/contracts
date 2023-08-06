// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Test.sol";
import "src/Policy.sol";

contract PolicyTest is Test {
    address public owner = address(50);
    Policy public policy;

    function setUp() public {
        vm.prank(owner);
        policy = new Policy();
    }

    function test_CreatePolicy() public {
        assertEq(policy.policyCounter(), 0);
        vm.prank(owner);
        policy.createPolicy(block.number, address(1));
        assertEq(policy.policyCounter(), 1);
        assertEq(policy.policyId(block.number, address(1)), 0);
    }

    function test_SubscribeAsInsured() public {
        vm.prank(owner);
        policy.createPolicy(block.number, address(1));
        vm.prank(address(2));
        policy.subscribeAsInsured(0, 100);
        assertEq(policy.amountAsInsured(0, address(2)), 100);
        assertEq(policy.fifoInsured(0, 0), address(2));
    }

    function test_SubscribeAsInsurer() public {
        vm.prank(owner);
        policy.createPolicy(block.number, address(1));
        vm.prank(address(2));
        policy.subscribeAsInsurer(0, 100);
        assertEq(policy.amountAsInsurer(0, address(2)), 100);
        assertEq(policy.fifoInsurer(0, 0), address(2));
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        policy.createPolicy(block.number, address(1));
    }
}
