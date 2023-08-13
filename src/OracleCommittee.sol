// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPolicyManager} from "./interfaces/IPolicyManager.sol"; //TODO get an interface
import {IOracleCommittee} from "./interfaces/IOracleCommittee.sol";
import {GenericDataProvider} from "./GenericDataProvider.sol";

import "forge-std/console.sol";

// OracleCommittee sets up a series of data providers.
// When a majority of data providers report themselves as depegged, then it will report the policy as claimable
contract OracleCommittee is IOracleCommittee, Ownable {
    uint256 public startingBlock;
    uint256 public endingBlock;
    uint256 public minProvidersForQuorum;
    uint256 public policyId;
    uint8 public providersReportingDepeg;
    address public systemAddress;
    address public l1TokenAddress;
    bytes32 public symbol;
    bool private policySet = false;
    //DataProvider => depegged

    IPolicyManager public policyManager;

    enum ProviderStatus {
        NotRegistered,
        RegisteredButNotDepegged,
        RegisteredAndDepegged
    }

    event OracleCommitteeCreated(
        bytes32 indexed symbol,
        address indexed l1TokenAddress,
        uint256 startingBlock,
        uint256 endingBlock,
        address systemAddress
    );

    mapping(address => ProviderStatus) public depeggedProviders;
    address[] public providers; // Used to return a list of providers to the OP Stack hack

    modifier onlyOwnerOrPolicy() {
        require(
            msg.sender == owner() || msg.sender == address(policyManager), "Only owner or policy can call this function"
        );
        _;
    }

    modifier requirePolicySet() {
        require(policySet, "Policy has not been set");
        _;
    }

    constructor(bytes32 _symbol, address _l1TokenAddress, uint256 _startingBlock, uint256 _endingBlock) {
        require(_l1TokenAddress != address(0), "L1 token address must be specified");
        require(_startingBlock < _endingBlock, "Starting block must be before ending block");
        //require _symbol is not empty
        require(_symbol != bytes32(0), "Symbol must be specified");

        symbol = _symbol;
        l1TokenAddress = _l1TokenAddress;
        // systemAddress = policy.getSystemAddress();
        startingBlock = _startingBlock;
        endingBlock = _endingBlock;
        emit OracleCommitteeCreated(_symbol, _l1TokenAddress, _startingBlock, _endingBlock, systemAddress);
    }

    function recordProviderAsDepegged() external requirePolicySet {
        require(startingBlock <= block.number, "Committee has not started yet");

        require(
            depeggedProviders[msg.sender] == ProviderStatus.RegisteredButNotDepegged,
            "provider is either not registered or already depegged"
        );
        depeggedProviders[msg.sender] = ProviderStatus.RegisteredAndDepegged;
        providersReportingDepeg++;
        //Is the majority of providers depegged?
        if (providersReportingDepeg >= minProvidersForQuorum) {
            policyManager.depegEndPolicy(policyId);
        }
    }

    function isDepegged() external view returns (bool) {
        if (block.number < startingBlock) {
            console.log("starting block is less than block number, committee hasn't started, can't be depegged");
            return false;
        } //TODO, this should be L1 blocknum

        return providersReportingDepeg >= minProvidersForQuorum;
    }

    function isClosed() external view returns (bool) {
        // console.log("%s", block.number);
        // console.log("%s", startingBlock);
        // console.log("%s", endingBlock);
        // console.log("%s", this.isDepegged());
        return this.isDepegged() || block.number > endingBlock;
    }

    function getEndingBlock() external view returns (uint256) {
        return endingBlock;
    }

    function getPolicyAddress() external view returns (address) {
        return address(policyManager);
    }

    function recordPriceForProvider(address _provider, uint256 _l1BlockNum, uint256 _price)
        external
        requirePolicySet
        onlyOwnerOrPolicy
    {
        require(
            depeggedProviders[_provider] == ProviderStatus.RegisteredButNotDepegged,
            "provider is either not registered or already depegged"
        );
        console.log("From committee, recording prices for %s", _provider);
        GenericDataProvider provider = GenericDataProvider(_provider);
        provider.recordPrice(_l1BlockNum, _price);
    }

    // Shortcut, makes it easier to start an oracle committee from scratch
    function addNewProvider(
        bytes32 _oracleType,
        uint256 _depegTolerance,
        uint8 _minBlocksToSwitchStatus,
        uint8 _decimals,
        bool _isOnChain
    ) external requirePolicySet onlyOwnerOrPolicy returns (address) {
        //TODO Uncomment below for real contract.
        // require(block.number < startingBlock, "Committee has already started"); // TODO Is the starting block L1 or L2?
        require(!this.isClosed(), "Committee is closed");
        require(depeggedProviders[msg.sender] == ProviderStatus.NotRegistered, "Provider already registered");
        // TODO onlyOwner is being used for demo, but really only system address should be able to call this
        // require(msg.sender == systemAddress, "Only the system can add providers");

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

    function setPolicy(address _policy, uint256 _policyId) external onlyOwnerOrPolicy {
        require(!policySet, "Policy already set");
        require(_policy != address(0), "Policy must be specified");
        policyManager = IPolicyManager(_policy);
        policyId = _policyId;
        policySet = true;
    }

    function getProviders() external view returns (address[] memory) {
        return providers;
    }

    struct OnlyTheMostRelevantOracleMetadata {
        bytes32 symbol;
        address l1TokenAddress;
        uint256 startingBlock;
        uint256 endingBlock;
        uint256 providersReportingDepeg;
        address[] providers;
    }

    function getOracleMetadata() external view returns (OnlyTheMostRelevantOracleMetadata memory) {
        return OnlyTheMostRelevantOracleMetadata({
            symbol: symbol,
            l1TokenAddress: l1TokenAddress,
            startingBlock: startingBlock,
            endingBlock: endingBlock,
            providersReportingDepeg: providersReportingDepeg,
            providers: providers
        });
    }
}
