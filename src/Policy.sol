// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Policy is Ownable {
    uint256 public policyCounter = 0;

    // blocknumber => currency => policyId
    mapping(uint256 => mapping(address => uint256)) public policyId;
    // policyId => subscriber => amountAsInsured
    mapping(uint256 => mapping(address => uint256)) public amountAsInsured;
    // policyId => fifoInsured
    mapping(uint256 =>  address[]) public fifoInsured;
    // policyId => subscriber => amountAsInsurer
    mapping(uint256 => mapping(address => uint256)) public amountAsInsurer;
    // policyId => fifoInsurer
    mapping(uint256 =>  address[]) public fifoInsurer;

    function createPolicy(uint256 blockNumber, address currency) public onlyOwner {
        policyId[blockNumber][currency] = policyCounter;
        policyCounter++;
    }

    // Subcribes to an upcoming policy as insured
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
}

