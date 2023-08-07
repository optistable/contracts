// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Policy is Ownable {
    uint256 public policyCounter = 0;

    // blocknumber => currencyInsured => currencyInsurer => policyId
    mapping(uint256 => mapping(address => mapping(address => uint256))) public policyId;
    // policyId => subscriber => amountAsInsured
    mapping(uint256 => mapping(address => uint256)) public amountAsInsured;
    // policyId => fifoInsured
    mapping(uint256 => address[]) public fifoInsured;
    // policyId => subscriber => amountAsInsurer
    mapping(uint256 => mapping(address => uint256)) public amountAsInsurer;
    // policyId => fifoInsurer
    mapping(uint256 => address[]) public fifoInsurer;

    event PolicyCreated(
        uint256 indexed policyId, uint256 indexed blockNumber, address indexed currencyInsured, address currencyInsurer
    );

    modifier onlySystemAddress() {
        require(msg.sender == 0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001, "Only system address");
        _;
    }

    function createPolicy(uint256 blockNumber, address currencyInsured, address currencyInsurer) public onlyOwner {
        policyId[blockNumber][currencyInsured][currencyInsurer] = policyCounter;
        policyCounter++;

        emit PolicyCreated(policyCounter - 1, blockNumber, currencyInsured, currencyInsurer);
    }

    // Subcribes to an upcoming policy as insured
    // TODO: frh -> add events
    function subscribeAsInsured(uint256 _policyId, uint256 amount) public {
        amountAsInsured[_policyId][msg.sender] = amount;
        uint256 _fifoLength = fifoInsured[_policyId].length;
        address[] memory fifo = new address[](_fifoLength + 1);
        fifo[_fifoLength] = msg.sender;
        fifoInsured[_policyId] = fifo;
    }

    // Subcribes to an upcoming policy as insurer
    function subscribeAsInsurer(uint256 _policyId, uint256 amount) public {
        amountAsInsurer[_policyId][msg.sender] = amount;
        uint256 _fifoLength = fifoInsurer[_policyId].length;
        address[] memory fifo = new address[](_fifoLength + 1);
        fifo[_fifoLength] = msg.sender;
        fifoInsurer[_policyId] = fifo;
    }

    function activatePolicy(uint256 _policyId) public onlySystemAddress {}

    function endPolicy(uint256 _policyId) public onlySystemAddress {}
}
