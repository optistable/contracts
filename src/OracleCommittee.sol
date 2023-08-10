// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {IDataProvider} from "./IDataProvider.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/v0.8/interfaces/AggregatorV3Interface.sol";
import {Policy} from "./Policy.sol"; //TODO get an interface
import {GenericDataProvider} from "./GenericDataProvider.sol";
import "forge-std/console.sol";

// OracleCommittee sets up a series of data providers.
// When a majority of data providers report themselves as depegged, then it will report the policy as claimable
contract OracleCommittee is Ownable {
    uint256 startingBlock;
    uint256 endingBlock;
    uint8 minProvidersForQuorum;
    uint8 providersReportingDepeg;
    address systemAddress;
    //DataProvider => depegged

    Policy policy;

    enum ProviderStatus {
        NotRegistered,
        RegisteredButNotDepegged,
        RegisteredAndDepegged
    }

    mapping(address => ProviderStatus) depeggedProviders;
    address[] providers; // Used to return a list of providers to the OP Stack hack

    modifier onlyPolicy() {
        require(msg.sender == address(policy));
        _;
    }

    constructor(
        address _policy,
        uint8 _minProvidersForQuorum,
        uint256 _startingBlock,
        uint256 _endingBlock,
        address[] memory _providers
    ) {
        require(_policy != address(0), "Policy must be specified");
        require(
            _minProvidersForQuorum <= _providers.length, "Quorum must require less than the total number of providers"
        );
        require(_providers.length >= 1, "You must specify one or more data providers for the committee");
        policy = Policy(_policy);
        minProvidersForQuorum = _minProvidersForQuorum;
        startingBlock = _startingBlock;
        endingBlock = _endingBlock;
        // systemAddress = Policy(_policy).systemAddress();
        // Load providers into mapping
        for (uint256 i = 0; i < _providers.length; i++) {
            require(
                depeggedProviders[_providers[i]] == ProviderStatus.NotRegistered,
                "You can't use the same data provider twice"
            );
            depeggedProviders[_providers[i]] = ProviderStatus.RegisteredButNotDepegged;
            providers.push(_providers[i]);
        }
    }

    function recordProviderAsDepegged() external {
        require(
            depeggedProviders[msg.sender] != ProviderStatus.RegisteredButNotDepegged,
            "provider is either not regitered or already depegged"
        );
        depeggedProviders[msg.sender] = ProviderStatus.RegisteredAndDepegged;
        providersReportingDepeg++;
    }

    function getStartingBlock() public view returns (uint256) {
        return startingBlock;
    }

    function getEndingBlock() public view returns (uint256) {
        return endingBlock;
    }

    function isDepegged() external view returns (bool) {
        return providersReportingDepeg >= minProvidersForQuorum;
    }

    function isClosed() external view returns (bool) {
        return this.isDepegged() || block.number > endingBlock;
    }

    function getProviders() external view returns (address[] memory) {
        return providers;
    }

    function addProvider(address _provider) external {
        require(startingBlock > block.number, "Committee has already started"); // TODO Is the starting block L1 or L2?
        require(depeggedProviders[_provider] == ProviderStatus.NotRegistered, "Provider already registered");
        IDataProvider iProvider = IDataProvider(_provider);
        require(iProvider.getOracleCommittee() == address(0), "provider already registered with another committee");
        depeggedProviders[_provider] = ProviderStatus.RegisteredButNotDepegged;
        providers.push(_provider);
    }
}
