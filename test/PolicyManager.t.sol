// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Test.sol";
import "../src/PolicyManager.sol";
import "../src/mocks/MockStable.sol";
import "../src/OracleCommittee.sol";

contract PolicyTest is Test {
    MockStable public stableInsuredContract;
    MockStable public stableInsurerContract;
    address public stableInsured;
    address public stableInsurer;
    address public owner = address(50);
    PolicyManager public policyManager;
    // address public systemAddress = address(0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001);

    event PolicyCreated(
        uint256 indexed policyId, uint256 indexed blockNumber, address indexed currencyInsured, address currencyInsurer
    );

    function setUp() public {
        vm.prank(owner);
        policyManager = new PolicyManager(0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001);
        setUpStablecoins();
    }

    function assignPolicyToOracleCommittee(uint256 policyId) public {
        vm.startPrank(owner);
        OracleCommittee committee = new OracleCommittee(
            policyManager.policyAssetSymbolBytes32(policyId),
            policyManager.policyAsset(policyId),
            policyManager.policyBlock(policyId),
            policyManager.policyBlock(policyId) + policyManager.blocksPerYear()
        );
        committee.setPolicy(address(policyManager), policyId);
        console.log("Finished creating committee, assigning committee to policy");
        policyManager.setOracleCommittee(policyId, address(committee));
        vm.stopPrank();
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
        uint256 policyId = policyManager.createPolicy(block.number, stableInsured, stableInsurer, 5);
        assignPolicyToOracleCommittee(policyId);
        for (uint256 i = 1; i < 11; i++) {
            if (uint256(i) % uint256(2) == uint256(0)) {
                address insurer = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
                uint256 insurerQty = 25e18 + 1e18 * i;
                deal(stableInsurer, insurer, insurerQty);
                vm.startPrank(insurer);
                stableInsurerContract.approve(address(policyManager), insurerQty);
                policyManager.subscribeAsInsurer(0, insurerQty);
                vm.stopPrank();
            }
            address insured = address(uint160(uint256(keccak256(abi.encodePacked(i + 20)))));
            uint256 insuredQty = 50e18 + 2e18 * i;
            uint256 insuredQtyPlusPremium = insuredQty * 5 / 10 + insuredQty;

            deal(stableInsured, insured, insuredQtyPlusPremium);
            vm.startPrank(insured);
            stableInsuredContract.approve(address(policyManager), insuredQtyPlusPremium);
            policyManager.subscribeAsInsured(0, insuredQty);
            vm.stopPrank();
        }
    }

    function test_ActivatePolicy() public {
        seedSubscribersMoreInsureds();
        vm.prank(owner);
        policyManager.activatePolicy(0);
        // collateralWrapper
        for (uint256 i = 1; i < 11; i++) {
            if (uint256(i) % uint256(2) == uint256(0)) {
                address insurer = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
                uint256 insurerQty = 25e18 + 1e18 * i;
                assertEq(policyManager.collateralWrapper(0).balanceOf(insurer), insurerQty);
            }
        }
    }

    function test_CreatePolicy() public {
        assertEq(policyManager.policyCounter(), 0);
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit PolicyCreated(0, block.number, stableInsured, stableInsurer);
        uint256 policyId = policyManager.createPolicy(block.number, stableInsured, stableInsurer, 5);
        assignPolicyToOracleCommittee(policyId);

        assertEq(policyManager.policyPremiumPCT(0), 5);
        assertEq(policyManager.policyCounter(), 1);
        assertEq(policyManager.policyId(block.number, stableInsured, stableInsurer), 0);
        assertEq(policyManager.policyBlock(0), block.number);
        assertEq(policyManager.policyAsset(0), stableInsured);
        assertEq(policyManager.policyCollateral(0), stableInsurer);
        assertEq(
            policyManager.assetWrapper(0).name(),
            string.concat("i", stableInsuredContract.name(), "-", vm.toString(block.number))
        );
        assertEq(
            policyManager.assetWrapper(0).symbol(),
            string.concat("i", stableInsuredContract.symbol(), vm.toString(block.number))
        );
        assertEq(
            policyManager.collateralWrapper(0).name(),
            string.concat("c", stableInsurerContract.name(), "-", vm.toString(block.number))
        );
        assertEq(
            policyManager.collateralWrapper(0).symbol(),
            string.concat("c", stableInsurerContract.symbol(), vm.toString(block.number))
        );
    }

    function test_DepegEndPolicy() public {
        seedSubscribersMoreInsureds();
        vm.prank(owner);
        policyManager.activatePolicy(0);
        vm.roll(1000);
        vm.prank(owner);
        policyManager.depegEndPolicy(0);
        for (uint256 i = 1; i < 11; i++) {
            if (uint256(i) % uint256(2) == uint256(0)) {
                address insurer = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
                uint256 insurerQty = 25e18 + 1e18 * i;
                assertEq(
                    stableInsuredContract.balanceOf(insurer),
                    insurerQty * policyManager.policyPremiumPCT(0) / 100 + insurerQty
                );
            }
        }
    }

    function test_SubscribeAsInsured() public {
        vm.prank(owner);
        uint256 policyId = policyManager.createPolicy(block.number, stableInsured, stableInsurer, 5);
        assignPolicyToOracleCommittee(policyId);
        vm.prank(stableInsurer);
        policyManager.subscribeAsInsured(0, 25e18);
        assertEq(policyManager.amountAsInsured(0, stableInsurer), 25e18);
        assertEq(policyManager.fifoInsured(0, 0), stableInsurer);
    }

    function test_SubscribeAsInsurer() public {
        vm.prank(owner);
        uint256 policyId = policyManager.createPolicy(block.number, stableInsured, stableInsurer, 5);
        assignPolicyToOracleCommittee(policyId);
        vm.prank(stableInsurer);
        policyManager.subscribeAsInsurer(0, 25e18);
        assertEq(policyManager.amountAsInsurer(0, stableInsurer), 25e18);
        assertEq(policyManager.fifoInsurer(0, 0), stableInsurer);
    }

    function test_WithdrawAsInsured() public {
        vm.prank(owner);
        uint256 policyId = policyManager.createPolicy(block.number, stableInsured, stableInsurer, 5);
        assignPolicyToOracleCommittee(policyId);
        deal(stableInsured, address(policyManager), 5e18);
        deal(address(policyManager.assetWrapper(0)), address(5), 5e18);
        assertEq(stableInsuredContract.balanceOf(address(policyManager)), 5e18);
        assertEq(policyManager.assetWrapper(0).balanceOf(address(5)), 5e18);
        vm.prank(address(5));
        policyManager.withdrawAsInsured(0, 5e18);
        assertEq(stableInsuredContract.balanceOf(address(policyManager)), 0);
        assertEq(policyManager.assetWrapper(0).balanceOf(address(5)), 0);
        assertEq(stableInsuredContract.balanceOf(address(5)), 5e18);
    }

    function test_WithdrawAsInsurer() public {
        vm.prank(owner);
        uint256 policyId = policyManager.createPolicy(block.number, stableInsured, stableInsurer, 5);
        assignPolicyToOracleCommittee(policyId);
        deal(stableInsurer, address(policyManager), 5e18);
        deal(address(policyManager.collateralWrapper(0)), address(5), 5e18);
        assertEq(stableInsurerContract.balanceOf(address(policyManager)), 5e18);
        assertEq(policyManager.collateralWrapper(0).balanceOf(address(5)), 5e18);
        vm.roll(policyManager.blocksPerYear() + 1000);
        vm.prank(address(5));
        policyManager.withdrawAsInsurer(0, 5e18);
        assertEq(stableInsurerContract.balanceOf(address(policyManager)), 0);
        assertEq(policyManager.collateralWrapper(0).balanceOf(address(5)), 0);
        assertEq(stableInsurerContract.balanceOf(address(5)), 5e18);
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        uint256 policyId = policyManager.createPolicy(block.number, stableInsured, stableInsurer, 5);
    }

    function test_RevertWhen_InsurerWithdrawsButPolicyActibe() public {
        vm.prank(owner);
        uint256 policyId = policyManager.createPolicy(block.number, stableInsured, stableInsurer, 5);
        assignPolicyToOracleCommittee(policyId);
        deal(stableInsurer, address(policyManager), 5e18);
        deal(address(policyManager.collateralWrapper(0)), address(5), 5e18);
        vm.prank(address(5));
        vm.expectRevert("Policy still active");
        policyManager.withdrawAsInsurer(0, 5e18);
    }

    function test_RevertWhen_MinimumIsNotSubscribed() public {
        vm.prank(owner);
        uint256 policyId = policyManager.createPolicy(block.number, stableInsured, stableInsurer, 5);
        assignPolicyToOracleCommittee(policyId);
        vm.prank(stableInsurer);
        vm.expectRevert("Minimum not subcribed");
        policyManager.subscribeAsInsured(0, 1e18);
        vm.prank(stableInsurer);
        vm.expectRevert("Minimum not subcribed");
        policyManager.subscribeAsInsurer(0, 5e18);
    }

    function test_RevertWhen_WithdrawerHasNotEnoughFunds() public {
        vm.prank(owner);
        uint256 policyId = policyManager.createPolicy(block.number, stableInsured, stableInsurer, 5);
        assignPolicyToOracleCommittee(policyId);
        vm.expectRevert("Not enough balance");
        policyManager.withdrawAsInsured(0, 50);
    }
}
