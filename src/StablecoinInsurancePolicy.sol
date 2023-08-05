// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IStablecoinInsurancePolicy} from "./IStablecoinInsurancePolicy.sol";
import {IDataProvider} from "./IDataProvider.sol";
import "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StablecoinInsurancePolicy is IStablecoinInsurancePolicy {
    enum PolicyState {
        AwaitingInsurer,
        Active,
        Depegged,
        Cancelled,
        Executed
    }
    address managementContract; // Where it applies, the management contract that created this policy,
    address insured;
    address insurer;
    IERC20 insuredToken;
    IERC20 collateralToken;
    IERC20 premiumToken; //Should this be collateral token?
    uint256 insuredAmount;
    uint256 policyTermInSeconds;

    // Start balances at 0 so we can deploy -> approve -> transfer
    uint256 insuredBalance = 0;
    uint256 collateralBalance = 0;
    uint256 lockedPremiumBalance = 0; // Trickles into unlocked premium balance whenever depeg is checked
    uint256 unlockedPremiumBalance = 0; // Can be withdrawn on demand by the insurer
    uint256 requiredPremium;

    uint256 depegTermInSeconds;
    uint256 timeDepegged; // When depeg is detected, incremented until depegTerm is hit. Reset to 0 if the policy is no longer depegged
    uint256 lastBlockChecked; //block number is more reliable than block timestamp???
    uint32 averageBlockTimeInSeconds = 10;
    PolicyState status;
    uint256 startDate;
    IDataProvider dataProvider; // used to get the price of the insured token

    modifier onlyInsured() {
        require(
            msg.sender == insured,
            "Only the insured can call this function"
        );
        _;
    }
    modifier onlyInsurer() {
        require(
            msg.sender == insurer,
            "Only the insurer can call this function"
        );
        _;
    }
    // modifier mustHaveStatus(PolicyState _status) {
    //     require(status == _status, string.concat("Policy must be in state ", _status));
    //     _;
    // }
    modifier mustBeActive() {
        require(
            status != PolicyState.AwaitingInsurer &&
                status != PolicyState.Cancelled &&
                status != PolicyState.Executed,
            string.concat("Policy must be in an active state")
        );
        _;
    }

    constructor(
        address _insured,
        address _insuredToken,
        address _insurerToken,
        address _premiumToken,
        uint256 _insuredAmount,
        uint256 _premiumAmount,
        uint256 _policyTermInSeconds,
        uint256 _depegTermInSeconds,
        address _dataProvider,
        address _managementContract
    ) payable {
        // require(_insured != _insurer, "Insured and insurer must be different"); // Also captures if both _insured and _insurer are empty
        require(_insuredToken != address(0), "Insured token must be specified");
        require(
            _insurerToken != address(0),
            "Collateral token must be specified"
        );
        require(_premiumToken != address(0), "Premium token must be specified");
        require(
            _insuredToken != _insurerToken,
            "Insured token and collateral token must be different"
        );
        require(_insuredAmount > 0, "Insured amount must be greater than 0");
        require(_premiumAmount > 0, "Premium must be greater than 0");
        require(_dataProvider != address(0), "Data provider must be specified");

        insured = _insured;
        insuredToken = IERC20(_insuredToken);
        collateralToken = IERC20(_insurerToken);
        premiumToken = IERC20(_premiumToken);
        insuredAmount = _insuredAmount;
        requiredPremium = _premiumAmount;
        policyTermInSeconds = _policyTermInSeconds;
        depegTermInSeconds = _depegTermInSeconds;
        dataProvider = IDataProvider(_dataProvider);
        startDate = block.timestamp;
        status = PolicyState.Active;
        managementContract = _managementContract;
    }

    function setDataProvider(address _newDataProvider) external {
        // TODO, this should require a signature from both the insured and the insurer
        require(false, "Not implemented yet");
        dataProvider = IDataProvider(_newDataProvider);
    }

    function insuredDeposit() external payable onlyInsured {
        uint256 requiredDeposit = insuredAmount + requiredPremium;
        // TODO, this won't be done w/ native tokens
        require(
            insuredToken.allowance(msg.sender, address(this)) >=
                requiredDeposit,
            "Insured must approve the policy to transfer the required amount"
        );
        require(
            insuredToken.balanceOf(msg.sender) >= requiredDeposit,
            "Insured must deposit the required amount"
        );
        require(
            insuredToken.transferFrom(
                msg.sender,
                address(this),
                requiredDeposit
            ),
            "Insured must transfer the required amount"
        );
        insuredBalance += requiredDeposit;
    }

    function insurerDeposit() external payable onlyInsurer {
        // TODO, this won't be done w/ native tokens
        require(
            insuredToken.allowance(msg.sender, address(this)) >= insuredAmount,
            "Insured must approve the policy to transfer the required amount"
        );
        require(
            insuredToken.balanceOf(msg.sender) >= insuredAmount,
            "Insured must deposit the required amount"
        );
        require(
            insuredToken.transferFrom(msg.sender, address(this), insuredAmount),
            "Insured must transfer the required amount"
        );
        collateralBalance += msg.value;
    }

    function activatePolicy() external onlyInsurer {
        require(
            status == PolicyState.AwaitingInsurer,
            "Policy must be awaiting insurer"
        );
        require(
            insuredBalance >= insuredAmount,
            "Insured must deposit the required amount"
        );
        require(
            lockedPremiumBalance >= requiredPremium,
            "Insured must deposit the premium"
        );
        require(
            collateralBalance >= insuredAmount,
            "Insurer must deposit the required amount"
        );
        status = PolicyState.Active;
    }

    function isDepegged() external view returns (bool) {
        // (uint insuredPrice, uint collateralPrice) = dataProvider
        // .getCurrentPrices(address(insuredToken), address(collateralToken));
        // // Check if insured token has deviated from collateral token by some percentage
        // Or since these are stablecoins, should it be that it has deviated from 1?
        return false;
    }

    function recordDepeg() external mustBeActive {
        if (this.isDepegged()) {
            if (status == PolicyState.Depegged) {
                timeDepegged +=
                    (block.number - lastBlockChecked) *
                    averageBlockTimeInSeconds;
                console.log("timeDepegged: ", timeDepegged);
                if (timeDepegged >= depegTermInSeconds) {
                    console.log("Claim terms met");
                    executeClaim();
                }
            } else {
                status = PolicyState.Depegged;
            }
            lastBlockChecked = block.number;
        } else {
            timeDepegged = 0;
            status = PolicyState.Active;
        }
    }

    // If the depeg has
    //TODO Add reentracy protection
    function executeClaim() private mustBeActive {
        require(
            insuredToken.transferFrom(address(this), insurer, insuredAmount),
            "failed to transfer insured token to insurer"
        );
        require(
            premiumToken.transferFrom(
                address(this),
                insured,
                lockedPremiumBalance
            )
        );
        require(
            collateralToken.transferFrom(
                address(this),
                insured,
                collateralBalance + unlockedPremiumBalance
            ),
            "failed to transfer collateral token to insured"
        );
        require(
            premiumToken.transferFrom(
                address(this),
                insured,
                unlockedPremiumBalance
            )
        );
        insuredBalance = 0;
        collateralBalance = 0;
        lockedPremiumBalance = 0;
        unlockedPremiumBalance = 0;
        status = PolicyState.Executed;
    }

    //TODO Add reentracy protection
    function cancelPolicy() external mustBeActive onlyInsured {
        console.log("Cancelling policy");
        //set insuredBalance to 0
        //set collateralBalance to 0
        //set locked premium balance to 0
        //set unlocked premium balance to 0
        //send insuredBalance to insured
        //send lockedPremiumBalance to insured
        //send collateralBalance to insurer
        //send unlockedPremiumBalance to insurer
        //mark policy as cancelled
        status = PolicyState.Cancelled;
    }

    //TODO Add reentracy protection
    function withdrawPremium() external mustBeActive onlyInsurer {
        //send unlockedPremiumBalance to insurer
    }
}
