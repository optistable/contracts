// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {IInsurance} from "./interfaces/IInsurance.sol";
import {IDataProvider} from "./interfaces/IDataProvider.sol";
import "forge-std/Console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Insurance is IInsurance {
    using SafeMath for uint256;

    struct Insurer {
        address participantAddress;
        uint256 amount;
        uint256 joinTimestamp;
        uint256 insuranceTimeInSeconds;
        address[] matchedInsureds; // The matched Insured addresses
    }

    struct Insured {
        address participantAddress;
        uint256 amount;
        uint256 joinTimestamp;
        uint256 insuranceTimeInSeconds;
        address matchedInsurer; // The matched Insurer's address
    }

    address public managementContract;
    IERC20 public insuredToken;
    IERC20 public collateralToken; // Collateral and premium token
    uint256 public premiumRate; // In percentage

    mapping(address => Insured) public insuredsMap;
    mapping(address => Insurer) public insurersMap;
    address[] public insuredsList;
    address[] public insurersList;

    uint256 public totalInsuredAmount;
    uint256 public totalCollateralAmount;

    uint256 public depegTermInSeconds;
    uint256 public depegThreshold;

    IDataProvider public dataProvider;

    modifier onlyInsured() {
        require(insuredsMap[msg.sender].participantAddress != address(0), "Only the insured can call this function");
        _;
    }

    modifier onlyInsurer() {
        require(insurersMap[msg.sender].participantAddress != address(0), "Only the insurer can call this function");
        _;
    }

    constructor(
        address _insuredToken,
        address _collateralToken,
        uint256 _depegTermInSeconds,
        uint256 _depegThreshold,
        uint256 _premiumRate,
        address _dataProvider,
        address _managementContract
    ) {
        insuredToken = IERC20(_insuredToken);
        collateralToken = IERC20(_collateralToken);
        depegTermInSeconds = _depegTermInSeconds;
        depegThreshold = _depegThreshold;
        premiumRate = _premiumRate;
        dataProvider = IDataProvider(_dataProvider);
        managementContract = _managementContract;
    }

    function getPossibleInsurerMatches(address insuredAddress) public view returns(address[] memory) {
        Insured memory insured = insuredsMap[insuredAddress];
        address[] memory possibleMatches = new address[](insurersList.length);

        uint256 count = 0;
        for (uint256 i = 0; i < insurersList.length; i++) {
            Insurer memory insurer = insurersMap[insurersList[i]];

            if (insurer.amount >= insured.amount && 
                block.timestamp <= insurer.joinTimestamp + insurer.insuranceTimeInSeconds) {
                possibleMatches[count] = insurersList[i];
                count++;
            }
        }
        return possibleMatches;
    }

    function addInsured(uint256 _amount, uint256 _insuranceTimeInSeconds, address insurerAddress) external {
        uint256 allowance = insuredToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Allowance not sufficient");
        
        insuredToken.transferFrom(msg.sender, address(this), _amount);

        Insured memory newInsured = Insured({
            participantAddress: msg.sender,
            amount: _amount,
            joinTimestamp: block.timestamp,
            insuranceTimeInSeconds: _insuranceTimeInSeconds,
            matchedInsurer: insurerAddress
        });

        insuredsList.push(msg.sender);
        insuredsMap[msg.sender] = newInsured;

        totalInsuredAmount += _amount;

        // Adding to the insurer's matched list
        Insurer storage insurer = insurersMap[insurerAddress];
        insurer.matchedInsureds.push(msg.sender);
    }

    function addInsurer(uint256 _amount, uint256 _insuranceTimeInSeconds) external {
        uint256 allowance = collateralToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Allowance not sufficient");
        
        collateralToken.transferFrom(msg.sender, address(this), _amount);

        Insurer memory newInsurer = Insurer({
            participantAddress: msg.sender,
            amount: _amount,
            joinTimestamp: block.timestamp,
            insuranceTimeInSeconds: _insuranceTimeInSeconds,
            matchedInsureds: new address[](0)
        });

        insurersList.push(msg.sender);
        insurersMap[msg.sender] = newInsurer;

        totalCollateralAmount += _amount;
    }

    function claimInsurance() external onlyInsured {
        Insured storage claimant = insuredsMap[msg.sender];
        require(claimant.participantAddress == msg.sender, "Not insured");
        require(claimant.matchedInsurer != address(0), "Insured has not been matched with an insurer.");

        // // Get the difference amount based on the depeg event.
        // uint256 amountToClaim = calculateClaimAmount(claimant.amount);
        
        // // Check if there's enough collateral to pay the insured.
        // require(collateralToken.balanceOf(address(this)) >= amountToClaim, "Not enough collateral to pay the insurance.");

        // // Transfer the claimed amount to the insured.
        // collateralToken.transfer(msg.sender, amountToClaim);
        
        // Deduct from total insured amount.
        totalInsuredAmount -= claimant.amount;

        // Remove the insured's record.
        delete insuredsMap[msg.sender];
    }

    function removeInsured(address insuredAddress) internal {
        delete insuredsMap[insuredAddress];
        for (uint i = 0; i < insuredsList.length - 1; i++) {
            if (insuredsList[i] == insuredAddress) {
                insuredsList[i] = insuredsList[insuredsList.length - 1];
                break;
            }
        }
        insuredsList.pop();
    }

    function claimPremium() external onlyInsurer {
        Insurer storage insurer = insurersMap[msg.sender];
        require(block.timestamp >= insurer.joinTimestamp + insurer.insuranceTimeInSeconds, "Insurance period for the insurer is not yet ended");
        
        uint256 totalPremium = insurer.amount * premiumRate / 100;

        // Iterate through matched insureds to deduct premiums
        for (uint i = 0; i < insurer.matchedInsureds.length; i++) {
            address insuredAddress = insurer.matchedInsureds[i];
            Insured storage insured = insuredsMap[insuredAddress];

            // For simplicity, we equally distribute the premium among all matched insureds.
            // This can be modified based on more complex logic if needed.
            uint256 individualPremium = totalPremium / insurer.matchedInsureds.length;

            // Checking if the insurer has enough balance to pay the premium
            require(collateralToken.balanceOf(address(this)) >= individualPremium, "Not enough collateral to pay the premium");

            // Transfer the premium to the insurer
            collateralToken.transfer(insurer.participantAddress, individualPremium);

            // Reduce the insured amount to avoid re-claiming of the same premium
            insured.amount -= individualPremium;
        }

        // Reset matchedInsureds for the insurer after claiming the premiums
        delete insurer.matchedInsureds;
    }
}
