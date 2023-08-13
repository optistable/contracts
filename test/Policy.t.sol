// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Test.sol";
import "../src/Policy.sol";
import "../src/mocks/MockStable.sol";

contract PolicyTest is Test {
    MockStable public stableInsuredContract;
    MockStable public stableInsurerContract;
    address public stableInsured;
    address public stableInsurer;
    address public owner = address(50);
    Policy public policy;
    // address public systemAddress = address(0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001);

    event PolicyCreated(
        uint256 indexed policyId, uint256 indexed blockNumber, address indexed currencyInsured, address currencyInsurer
    );

    function setUp() public {
        vm.prank(owner);
        policy = new Policy(0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001);
        setUpStablecoins();
    }

    function setUpStablecoins() public {
        stableInsuredContract = new MockStable();
        stableInsured = address(stableInsuredContract);
        stableInsurerContract = new MockStable();
        stableInsurer = address(stableInsurerContract);
    }

    // 10 insureds vs 5 insurers
    function seedSubscribersMoreInsureds() public {
        vm.prank(owner);
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5);
        for (uint256 i = 1; i < 11; i++) {
            if (uint256(i) % uint256(2) == uint256(0)) {
                address insurer = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
                uint256 insurerQty = 25e18 + 1e18 * i;
                deal(stableInsurer, insurer, insurerQty);
                vm.startPrank(insurer);
                stableInsurerContract.approve(address(policy), insurerQty);
                policy.subscribeAsInsurer(0, insurerQty);
                vm.stopPrank();
            }
            address insured = address(uint160(uint256(keccak256(abi.encodePacked(i + 20)))));
            uint256 insuredQty = 50e18 + 2e18 * i;
            uint256 insuredQtyPlusPremium = insuredQty * 5 / 10 + insuredQty;

            deal(stableInsured, insured, insuredQtyPlusPremium);
            vm.startPrank(insured);
            stableInsuredContract.approve(address(policy), insuredQtyPlusPremium);
            policy.subscribeAsInsured(0, insuredQty);
            vm.stopPrank();
        }
    }

    function test_ActivatePolicy() public {
        seedSubscribersMoreInsureds();
        vm.prank(owner);
        policy.activatePolicy(0);
        // collateralWrapper
        for (uint256 i = 1; i < 11; i++) {
            if (uint256(i) % uint256(2) == uint256(0)) {
                address insurer = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
                uint256 insurerQty = 25e18 + 1e18 * i;
                assertEq(policy.collateralWrapper(0).balanceOf(insurer), insurerQty);
            }
        }
    }

    function test_CreatePolicy() public {
        assertEq(policy.policyCounter(), 0);
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit PolicyCreated(0, block.number, stableInsured, stableInsurer);
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5);

        (uint256 premiumPCT, uint256 blockNumber, address asset, address collateral) = policy.policyMetadata(0);
        assertEq(premiumPCT, 5);
        assertEq(policy.policyCounter(), 1);
        assertEq(policy.policyId(block.number, stableInsured, stableInsurer), 0);
        assertEq(blockNumber, block.number);
        assertEq(asset, stableInsured);
        assertEq(collateral, stableInsurer);
        assertEq(
            policy.assetWrapper(0).name(),
            string.concat("i", stableInsuredContract.name(), "-", vm.toString(block.number))
        );
        assertEq(
            policy.assetWrapper(0).symbol(),
            string.concat("i", stableInsuredContract.symbol(), vm.toString(block.number))
        );
        assertEq(
            policy.collateralWrapper(0).name(),
            string.concat("c", stableInsurerContract.name(), "-", vm.toString(block.number))
        );
        assertEq(
            policy.collateralWrapper(0).symbol(),
            string.concat("c", stableInsurerContract.symbol(), vm.toString(block.number))
        );
    }

    function test_DepegEndPolicy() public {
        seedSubscribersMoreInsureds();
        vm.prank(owner);
        policy.activatePolicy(0);
        vm.roll(1000);
        vm.prank(owner);
        policy.depegEndPolicy(0);
        (uint256 premiumPCT,,,) = policy.policyMetadata(0);
        for (uint256 i = 1; i < 11; i++) {
            if (uint256(i) % uint256(2) == uint256(0)) {
                address insurer = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
                uint256 insurerQty = 25e18 + 1e18 * i;
                assertEq(stableInsuredContract.balanceOf(insurer), insurerQty * premiumPCT / 100 + insurerQty);
            }
        }
    }

    function test_SubscribeAsInsured() public {
        vm.prank(owner);
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5);
        vm.prank(stableInsurer);
        policy.subscribeAsInsured(0, 25e18);
        assertEq(policy.amountAsInsured(0, stableInsurer), 25e18);
        assertEq(policy.fifoInsured(0, 0), stableInsurer);
    }

    function test_SubscribeAsInsurer() public {
        vm.prank(owner);
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5);
        vm.prank(stableInsurer);
        policy.subscribeAsInsurer(0, 25e18);
        assertEq(policy.amountAsInsurer(0, stableInsurer), 25e18);
        assertEq(policy.fifoInsurer(0, 0), stableInsurer);
    }

    function test_WithdrawAsInsured() public {
        vm.prank(owner);
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5);
        deal(stableInsured, address(policy), 5e18);
        deal(address(policy.assetWrapper(0)), address(5), 5e18);
        assertEq(stableInsuredContract.balanceOf(address(policy)), 5e18);
        assertEq(policy.assetWrapper(0).balanceOf(address(5)), 5e18);
        vm.prank(address(5));
        policy.withdrawAsInsured(0, 5e18);
        assertEq(stableInsuredContract.balanceOf(address(policy)), 0);
        assertEq(policy.assetWrapper(0).balanceOf(address(5)), 0);
        assertEq(stableInsuredContract.balanceOf(address(5)), 5e18);
    }

    function test_WithdrawAsInsurer() public {
        vm.prank(owner);
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5);
        deal(stableInsurer, address(policy), 5e18);
        deal(address(policy.collateralWrapper(0)), address(5), 5e18);
        assertEq(stableInsurerContract.balanceOf(address(policy)), 5e18);
        assertEq(policy.collateralWrapper(0).balanceOf(address(5)), 5e18);
        vm.roll(policy.blocksPerYear() + 1000);
        vm.prank(address(5));
        policy.withdrawAsInsurer(0, 5e18);
        assertEq(stableInsurerContract.balanceOf(address(policy)), 0);
        assertEq(policy.collateralWrapper(0).balanceOf(address(5)), 0);
        assertEq(stableInsurerContract.balanceOf(address(5)), 5e18);
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5);
    }

    function test_RevertWhen_InsurerWithdrawsButPolicyActibe() public {
        vm.prank(owner);
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5);
        deal(stableInsurer, address(policy), 5e18);
        deal(address(policy.collateralWrapper(0)), address(5), 5e18);
        vm.prank(address(5));
        vm.expectRevert("Policy still active");
        policy.withdrawAsInsurer(0, 5e18);
    }

    function test_RevertWhen_MinimumIsNotSubscribed() public {
        vm.prank(owner);
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5);
        vm.prank(stableInsurer);
        vm.expectRevert("Minimum not subcribed");
        policy.subscribeAsInsured(0, 1e18);
        vm.prank(stableInsurer);
        vm.expectRevert("Minimum not subcribed");
        policy.subscribeAsInsurer(0, 5e18);
    }

    function test_RevertWhen_WithdrawerHasNotEnoughFunds() public {
        vm.prank(owner);
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5);
        vm.expectRevert("Not enough balance");
        policy.withdrawAsInsured(0, 50);
    }
}
