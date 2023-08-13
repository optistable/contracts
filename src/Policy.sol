// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
// import {OracleCommittee} from "./OracleCommittee.sol";
import {ERC20Helper} from "./libraries/ERC20Helper.sol";
import {PolicyWrapper} from "./PolicyWrapper.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
// import "forge-std/console.sol";

// solhint-disable-next-line max-states-count
contract Policy is Ownable {
    using Strings for uint256;

    address public systemAddress;
    uint256 public policyCounter = 0;
    // TODO: frh -> be able how to change this variables and solve solhint-disable with another contract but not
    // 100% necesary
    uint256 public subscribeMinimum = 10;
    uint256 public blocksPerYear = 2600000;

    // blocknumber => currencyInsured => currencyInsurer => policyId
    mapping(uint256 => mapping(address => mapping(address => uint256))) public policyId;
    // policyId => OracleCommittee

    // mapping(uint256 => OracleCommittee) public policyOracleCommittee;

    // policyId => policyPremiumPCT
    mapping(uint256 => uint256) public policyPremiumPCT;
    // policyId => blocknumber
    mapping(uint256 => uint256) public policyBlock;
    // policyId => currencyInsured
    mapping(uint256 => address) public policyAsset;
    // policyId => currencyInsurer
    mapping(uint256 => address) public policyCollateral;
    // policyId => assetWrapper
    mapping(uint256 => PolicyWrapper) public assetWrapper;
    // policyId => collateralWrapper
    mapping(uint256 => PolicyWrapper) public collateralWrapper;

    // policyId => subscriber => amountAsInsured
    mapping(uint256 => mapping(address => uint256)) public amountAsInsured;
    // policyId => fifoInsured
    mapping(uint256 => address[]) public fifoInsured;
    // policiyid => insuredIndex
    mapping(uint256 => uint256) private _insuredIndex;

    // policyId => subscriber => amountAsInsurer
    mapping(uint256 => mapping(address => uint256)) public amountAsInsurer;
    // policyId => fifoInsurer
    mapping(uint256 => address[]) public fifoInsurer;
    // policiyid => insurerIndex
    mapping(uint256 => uint256) private _insurerIndex;

    event PolicyCreated(
        uint256 indexed policyId, uint256 indexed blockNumber, address indexed currencyInsured, address currencyInsurer
    );

    // modifier onlySystemAddress() {
    //     require(msg.sender == systemAddress, "Only system address");
    //     _;
    // }

    modifier onlyOwnerOrOracleCommittee(uint256 _policyId) {
        // OracleCommittee o = policyOracleCommittee[_policyId];
        // require(
        // msg.sender == owner() || msg.sender == address(o), "Only system address or owner can call this function"
        // );
        _;
    }

    // constructor(address _systemAddress) {
    //     systemAddress = msg.sender; //TODO Temporarily set here to make it onlyOwner equivalent in case anything checks for sysAddress
    //         // systemAddress = _systemAddress;
    // }

    function createPolicy(
        uint256 blockNumber,
        address currencyInsured,
        address currencyInsurer,
        uint256 _policyPremiumPCT
    )
        public
        returns (
            /*onlyOwner*/
            uint256
        )
    {
        string memory currencyInsuredSymbol = ERC20Helper.symbol(currencyInsured);
        assetWrapper[policyCounter] = new PolicyWrapper();
        assetWrapper[policyCounter].setName(
            string.concat("i", ERC20Helper.name(currencyInsured), "-", blockNumber.toString())
        );
        assetWrapper[policyCounter].setSymbol(string.concat("i", currencyInsuredSymbol, blockNumber.toString()));
        collateralWrapper[policyCounter] = new PolicyWrapper();
        collateralWrapper[policyCounter].setName(
            string.concat("c", ERC20Helper.name(currencyInsurer), "-", blockNumber.toString())
        );
        collateralWrapper[policyCounter].setSymbol(
            string.concat("c", ERC20Helper.symbol(currencyInsurer), blockNumber.toString())
        );

        //Converst string symbol to bytes32
        bytes32 currencySymbol;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            currencyInsuredSymbol := mload(add(currencyInsuredSymbol, 32))
        }
        // policyOracleCommittee[policyCounter] = new OracleCommittee(
        //     policyCounter,
        //     address(this), currencySymbol, currencyInsured, blockNumber,
        //     blockNumber + blocksPerYear
        // );

        policyId[blockNumber][currencyInsured][currencyInsurer] = policyCounter;
        policyPremiumPCT[policyCounter] = _policyPremiumPCT;
        policyBlock[policyCounter] = blockNumber;
        policyAsset[policyCounter] = currencyInsured;
        policyCollateral[policyCounter] = currencyInsurer;
        policyCounter++;

        emit PolicyCreated(policyCounter - 1, blockNumber, currencyInsured, currencyInsurer);
        return policyCounter - 1;
    }

    // Depeg occurs, policy executes and ends
    // function depegEndPolicy(uint256 _policyId) public onlySystemAddress {
    function depegEndPolicy(uint256 _policyId) public onlyOwnerOrOracleCommittee(_policyId) {
        address _policyAsset = policyAsset[_policyId];
        address _policyCollateral = policyCollateral[_policyId];
        PolicyWrapper _assetWrapper = assetWrapper[_policyId];
        PolicyWrapper _collateralWrapper = collateralWrapper[_policyId];

        for (uint256 i = 0; i < _assetWrapper.getMintersLength(); i++) {
            address insured = _assetWrapper.getMinter(i);
            uint256 insuredBalance = _assetWrapper.balanceOf(insured);

            if (insuredBalance > 0) {
                _assetWrapper.burn(insured, insuredBalance);
                ERC20Helper.safeTransfer(_policyCollateral, insured, insuredBalance);
            }
        }

        for (uint256 i = 0; i < _collateralWrapper.getMintersLength(); i++) {
            address insurer = _collateralWrapper.getMinter(i);
            uint256 insurerBalance = _collateralWrapper.balanceOf(insurer);
            uint256 policyCollateralBalance = ERC20Helper.balanceOf(_policyCollateral, address(this));

            if (insurerBalance > 0) {
                // In case there is any collateral left it will go to the first subscribers as an incentive
                if (policyCollateralBalance > 0) {
                    bool isInsurerBalanceBigger = insurerBalance > policyCollateralBalance;
                    if (isInsurerBalanceBigger) {
                        _collateralWrapper.burn(insurer, insurerBalance);
                        ERC20Helper.safeTransfer(_policyCollateral, insurer, policyCollateralBalance);
                        ERC20Helper.safeTransfer(_policyAsset, insurer, insurerBalance - policyCollateralBalance);
                    } else {
                        _collateralWrapper.burn(insurer, insurerBalance);
                        ERC20Helper.safeTransfer(_policyCollateral, insurer, insurerBalance);
                    }
                } else {
                    _collateralWrapper.burn(insurer, insurerBalance);
                    ERC20Helper.safeTransfer(_policyAsset, insurer, insurerBalance);
                }
            }
        }
    }

    // Subcribes to an upcoming policy as insured
    // TODO: frh -> add events, approve here and require blocknumber and TODOs from PR and deploy
    function subscribeToPolicy(bool insured, uint256 _policyId, uint256 amount) public {
        address _currencyInsuredOrInsurer = insured ? policyAsset[_policyId] : policyCollateral[_policyId];
        uint256 unit = 10 ** ERC20Helper.decimals(_currencyInsuredOrInsurer);
        require(amount / unit >= subscribeMinimum, "Minimum not subcribed");

        if (insured) {
            amountAsInsured[_policyId][msg.sender] = amount;
            fifoInsured[_policyId].push(msg.sender);
        } else {
            amountAsInsurer[_policyId][msg.sender] = amount;
            fifoInsurer[_policyId].push(msg.sender);
        }
    }

    // Insured can withdraw whenever he want
    function withdrawFromPolicy(bool insured, uint256 _policyId, uint256 amount) public {
        require(policyBlock[_policyId] + blocksPerYear < block.number, "Policy still active");
        PolicyWrapper wrapper = insured ? assetWrapper[_policyId] : collateralWrapper[_policyId];
        require(wrapper.balanceOf(msg.sender) >= amount, "Not enough balance");
        address _policyToken = insured ? policyAsset[_policyId] : policyCollateral[_policyId];

        wrapper.burn(msg.sender, amount);
        ERC20Helper.safeTransfer(_policyToken, msg.sender, amount);
    }

    // Check allowance and balance of subscriber, if insufficient go to next subscriber
    function _checkSubscription(address subscriber, uint256 amount, uint256 _policyId, bool isInsuredAddress)
        private
        returns (bool)
    {
        bool sufficient = false;
        address currency = isInsuredAddress ? policyAsset[_policyId] : policyCollateral[_policyId];

        uint256 allowance = ERC20Helper.allowance(currency, subscriber);
        if (allowance < amount) {
            if (isInsuredAddress) _insuredIndex[_policyId]++;
            else _insurerIndex[_policyId]++;
        }

        uint256 balance = ERC20Helper.balanceOf(currency, subscriber);
        if (balance < amount && allowance >= amount) {
            if (isInsuredAddress) _insuredIndex[_policyId]++;
            else _insurerIndex[_policyId]++;
        }

        if (balance >= amount && allowance >= amount) {
            sufficient = true;
        }
        return sufficient;
    }

    function activatePolicy(uint256 _policyId) public onlyOwner {
        address insuredAddress = fifoInsured[_policyId][_insuredIndex[_policyId]];
        uint256 insuredAmount = amountAsInsured[_policyId][insuredAddress];
        uint256 premium = insuredAmount * policyPremiumPCT[_policyId] / 100;
        address insurerAddress = fifoInsurer[_policyId][_insurerIndex[_policyId]];
        uint256 insurerAmount = amountAsInsurer[_policyId][insurerAddress];

        bool canSubscribe = _checkSubscription(insuredAddress, insuredAmount + premium, _policyId, true)
            && _checkSubscription(insurerAddress, insurerAmount, _policyId, false);

        // If insurer and insured amount are the same we can pass onto the next ones
        if (insuredAmount == insurerAmount && canSubscribe) {
            _matchSubscribers(insuredAddress, insurerAddress, insuredAmount, _policyId);
            _insuredIndex[_policyId]++;
            _insurerIndex[_policyId]++;
        }

        // If insured amount is less than insurer we can pass only onto the next insured
        if (insuredAmount < insurerAmount && canSubscribe) {
            _matchSubscribers(insuredAddress, insurerAddress, insuredAmount, _policyId);
            _insuredIndex[_policyId]++;
        }

        // If insurer amount is less than insured we can pass only onto the next insurer
        if (insurerAmount < insuredAmount && canSubscribe) {
            _matchSubscribers(insuredAddress, insurerAddress, insurerAmount, _policyId);
            _insurerIndex[_policyId]++;
        }
        // If there are still subscribers we call the activate policy to go onto the next subscribers
        if (
            _insurerIndex[_policyId] < fifoInsurer[_policyId].length
                && _insuredIndex[_policyId] < fifoInsured[_policyId].length
        ) {
            activatePolicy(_policyId);
        }
    }

    function _matchSubscribers(address insured, address insurer, uint256 amount, uint256 _policyId) private {
        address _currencyAsset = policyAsset[_policyId];
        address _currencyCollateral = policyCollateral[_policyId];
        uint256 premium = amount * policyPremiumPCT[_policyId] / 100;

        require(amountAsInsured[_policyId][insured] >= amount, "Amount over subscription");
        require(amountAsInsurer[_policyId][insurer] >= amount, "Amount over subscription");
        amountAsInsured[_policyId][insured] = amountAsInsured[_policyId][insured] - amount;
        amountAsInsurer[_policyId][insurer] = amountAsInsurer[_policyId][insurer] - amount;

        ERC20Helper.safeTransferFrom(_currencyAsset, insured, address(this), amount);
        ERC20Helper.safeTransferFrom(_currencyAsset, insured, insurer, premium);
        ERC20Helper.safeTransferFrom(_currencyCollateral, insurer, address(this), amount);

        assetWrapper[_policyId].mint(insured, amount);
        collateralWrapper[_policyId].mint(insurer, amount);
    }
}
