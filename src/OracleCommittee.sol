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
    uint256 public startingBlock;
    uint256 public endingBlock;
    uint256 public minProvidersForQuorum;
    uint8 public providersReportingDepeg;
    address public systemAddress;
    address public l1TokenAddress;
    bytes32 public symbol;
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
        bytes32 _symbol,
        address _l1TokenAddress,
        uint256 _startingBlock,
        uint256 _endingBlock
    ) {
        require(_policy != address(0), "Policy must be specified");

        // require(_providers.length >= 1, "You must specify one or more data providers for the committee");
        policy = Policy(_policy);
        symbol = _symbol;
        l1TokenAddress = _l1TokenAddress;
        systemAddress = policy.systemAddress();
        startingBlock = _startingBlock;
        endingBlock = _endingBlock;
        // Load providers into mapping
        // for (uint256 i = 0; i < _providers.length; i++) {
        //     require(
        //         depeggedProviders[_providers[i]] == ProviderStatus.NotRegistered,
        //         "You can't use the same data provider twice"
        //     );
        //     depeggedProviders[_providers[i]] = ProviderStatus.RegisteredButNotDepegged;
        //     providers.push(_providers[i]);
        // }
    }

    function recordProviderAsDepegged() external {
        // require(len(providers) > 0, "No providers registered");
        //TODO @avichal, can we get the L1 block here?
        require(block.number >= startingBlock, "Committee has not started yet");
        require(
            depeggedProviders[msg.sender] != ProviderStatus.RegisteredButNotDepegged,
            "provider is either not registered or already depegged"
        );
        depeggedProviders[msg.sender] = ProviderStatus.RegisteredAndDepegged;
        providersReportingDepeg++;
        //Is the majority of providers depegged?
        // policy.endPolicy();
    }

    function getStartingBlock() public view returns (uint256) {
        return startingBlock;
    }

    function getEndingBlock() public view returns (uint256) {
        return endingBlock;
    }

    function isDepegged() external view returns (bool) {
        if (startingBlock <= block.number) {
            console.log("starting block is less than block number, committee hasn't started");
            return false;
        } //TODO, this should be L1 blocknum
        return providersReportingDepeg >= minProvidersForQuorum;
    }

    function isClosed() external view returns (bool) {
        return this.isDepegged() || block.number > endingBlock;
    }

    function getProviders() external view returns (address[] memory) {
        return providers;
    }

    function addExistingProvider(address _provider) external {
        require(startingBlock <= block.number, "Committee has already started"); // TODO Is the starting block L1 or L2?
        require(!this.isClosed(), "Committee is closed");
        require(msg.sender == systemAddress, "Only the system can add providers");
        require(depeggedProviders[_provider] == ProviderStatus.NotRegistered, "Provider already registered");
        IDataProvider iProvider = IDataProvider(_provider);
        require(iProvider.getOracleCommittee() == address(0), "provider already registered with another committee");
        depeggedProviders[_provider] = ProviderStatus.RegisteredButNotDepegged;
        providers.push(_provider);
    }

    // Shortcut, makes it easier
    function addNewProvider(
        bytes32 _oracleType,
        uint256 _depegTolerance,
        uint8 _minBlocksToSwitchStatus,
        uint8 _decimals,
        bool _isOnChain
    ) external returns (address) {
        require(startingBlock <= block.number, "Committee has already started"); // TODO Is the starting block L1 or L2?
        require(!this.isClosed(), "Committee is closed");
        // require(depeggedProviders[msg.sender] == ProviderStatus.NotRegistered, "Provider already registered");
        require(msg.sender == systemAddress, "Only the system can add providers");

        console.log("Creating new provider...");
        address newProvider = address(
            new GenericDataProvider(
            _oracleType,
            systemAddress, 
            address(this),
            symbol,
            _depegTolerance,
            _minBlocksToSwitchStatus,
            _decimals,
            _isOnChain
            )
        );
        depeggedProviders[newProvider] = ProviderStatus.RegisteredButNotDepegged;
        providers.push(newProvider);
        minProvidersForQuorum = (providers.length / 2) + (providers.length % 2);
 
        return newProvider;
    }
}
