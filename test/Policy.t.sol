// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Test.sol";
import "src/Policy.sol";

contract PolicyTest is Test {
    address public owner = address(50);
    Policy public policy;
    address public systemAddress = address(0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001);

    event PolicyCreated(
        uint256 indexed policyId, uint256 indexed blockNumber, address indexed currencyInsured, address currencyInsurer
    );

    function setUp() public {
        vm.prank(owner);
        policy = new Policy();
    }

    function test_CreatePolicy() public {
        assertEq(policy.policyCounter(), 0);
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit PolicyCreated(0, block.number, address(1), address(2));
        policy.createPolicy(block.number, address(1), address(2));
        assertEq(policy.policyCounter(), 1);
        assertEq(policy.policyId(block.number, address(1), address(2)), 0);
    }

    function test_SubscribeAsInsured() public {
        vm.prank(owner);
        policy.createPolicy(block.number, address(1), address(2));
        vm.prank(address(2));
        policy.subscribeAsInsured(0, 100);
        assertEq(policy.amountAsInsured(0, address(2)), 100);
        assertEq(policy.fifoInsured(0, 0), address(2));
    }

    function test_SubscribeAsInsurer() public {
        vm.prank(owner);
        policy.createPolicy(block.number, address(1), address(2));
        vm.prank(address(2));
        policy.subscribeAsInsurer(0, 100);
        assertEq(policy.amountAsInsurer(0, address(2)), 100);
        assertEq(policy.fifoInsurer(0, 0), address(2));
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        policy.createPolicy(block.number, address(1), address(2));
    }

    function test_RevertWhen_CallerIsNotSystemAddress() public {
        vm.expectRevert("Only system address");
        policy.activatePolicy(0);
    }
}
