//SPDX-License-Identifier: UNLICENSED
//solhint-disable custom-errors
pragma solidity ^0.8.18;

import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";

import { IEndorser } from "./interfaces/IEndorser.sol";
import { LibString } from "./LibString.sol";


struct Dc {
    bool _hasOperation;
    bool _explicitMaxBlockNumber;
    bool _explicitMaxBlockTimestamp;

    IEndorser.Operation _operation;

    IEndorser.GlobalDependency _globalDependency;
    IEndorser.Dependency[] _dependencies;
}

library LibDc {
    using FixedPointMathLib for *;
    using LibString for *;
    using LibDc for Dc;

    function create() internal pure returns (Dc memory _c) {}
    function create(IEndorser.Operation memory _operation) internal pure returns (Dc memory c) {
        c._operation = _operation;
        c._hasOperation = true;
    }

    function build(Dc memory _c) internal pure returns (
        bool,
        IEndorser.GlobalDependency memory,
        IEndorser.Dependency[] memory
    ) {
        if (!_c._explicitMaxBlockNumber) {
            _c._globalDependency.maxBlockNumber = type(uint256).max;
        }

        if (!_c._explicitMaxBlockTimestamp) {
            _c._globalDependency.maxBlockTimestamp = type(uint256).max;
        }

        return (true, _c._globalDependency, _c._dependencies);
    }

    function addBaseFee(Dc memory _c) internal pure returns (Dc memory) {
        _c._globalDependency.baseFee = true;
        return _c;
    }

    function addBlobBaseFee(Dc memory _c) internal pure returns (Dc memory) {
        _c._globalDependency.blobBaseFee = true;
        return _c;
    }

    function addChainId(Dc memory _c) internal pure returns (Dc memory) {
        _c._globalDependency.chainId = true;
        return _c;
    }

    function addCoinBase(Dc memory _c) internal pure returns (Dc memory) {
        _c._globalDependency.coinBase = true;
        return _c;
    }

    function addDifficulty(Dc memory _c) internal pure returns (Dc memory) {
        _c._globalDependency.difficulty = true;
        return _c;
    }

    function addGasLimit(Dc memory _c) internal pure returns (Dc memory) {
        _c._globalDependency.gasLimit = true;
        return _c;
    }

    function addNumber(Dc memory _c) internal pure returns (Dc memory) {
        _c._globalDependency.number = true;
        return _c;
    }

    function addTimestamp(Dc memory _c) internal pure returns (Dc memory) {
        _c._globalDependency.timestamp = true;
        return _c;
    }

    function addTxOrigin(Dc memory _c) internal pure returns (Dc memory) {
        _c._globalDependency.txOrigin = true;
        return _c;
    }

    function addTxGasPrice(Dc memory _c) internal pure returns (Dc memory) {
        _c._globalDependency.txGasPrice = true;
        return _c;
    }

    function addMaxBlockNumber(
        Dc memory _c,
        uint256 _maxBlockNumber
    ) internal pure returns (Dc memory) {
        if (!_c._explicitMaxBlockNumber) {
            _c._globalDependency.maxBlockNumber = _maxBlockNumber;
            _c._explicitMaxBlockNumber = true;
        } else {
            _c._globalDependency.maxBlockNumber = _c._globalDependency.maxBlockNumber.min(_maxBlockNumber);
        }

        return _c;
    }

    function addMaxBlockTimestamp(
        Dc memory _c,
        uint256 _maxBlockTimestamp
    ) internal pure returns(Dc memory) {
        if (!_c._explicitMaxBlockTimestamp) {
            _c._globalDependency.maxBlockTimestamp = _maxBlockTimestamp;
            _c._explicitMaxBlockTimestamp = true;
        } else {
            _c._globalDependency.maxBlockTimestamp = _c._globalDependency.maxBlockTimestamp.min(_maxBlockTimestamp);
        }

        return _c;
    }

    function _dependencyFor(
        Dc memory _c,
        address _addr
    ) internal pure returns (IEndorser.Dependency memory) {
        unchecked {
            for (uint256 i = 0; i != _c._dependencies.length; i++) {
                if (_c._dependencies[i].addr == _addr) {
                    return _c._dependencies[i];
                }
            }

            // We need to create a new dependency for this address, and add it to the carrier
            IEndorser.Dependency memory dep;
            dep.addr = _addr;

            IEndorser.Dependency[] memory newDeps = new IEndorser.Dependency[](_c._dependencies.length + 1);
            for (uint256 i = 0; i != _c._dependencies.length; i++) {
                newDeps[i] = _c._dependencies[i];
            }

            newDeps[_c._dependencies.length] = dep;
            _c._dependencies = newDeps;

            return dep;
        }
    }

    function addBalanceDependency(
        Dc memory _c,
        address _addr
    ) internal pure returns (Dc memory) {
        _c._dependencyFor(_addr).balance = true;
        return _c;
    }

    function addCodeDependency(
        Dc memory _c,
        address _addr
    ) internal pure returns (Dc memory) {
        _c._dependencyFor(_addr).code = true;
        return _c;
    }

    function addNonceDependency(
        Dc memory _c,
        address _addr
    ) internal pure returns (Dc memory) {
        _c._dependencyFor(_addr).nonce = true;
        return _c;
    }

    function addAllSlotsDependency(
        Dc memory _c,
        address _addr
    ) internal pure returns (Dc memory) {
        IEndorser.Dependency memory dep = _c._dependencyFor(_addr);
        dep.allSlots = true;
        // Slots and allSlots are mutually exclusive
        dep.slots = new bytes32[](0);
        return _c;
    }

    function addSlotDependency(
        Dc memory _c,
        address _addr,
        bytes32 _slot
    ) internal pure returns (Dc memory) {
        unchecked {
            IEndorser.Dependency memory dep = _c._dependencyFor(_addr);

            if (dep.allSlots) {
                // Slots and allSlots are mutually exclusive
                return _c;
            }

            for (uint256 i = 0; i != dep.slots.length; i++) {
                if (dep.slots[i] == _slot) {
                    return _c;
                }
            }

            bytes32[] memory newSlots = new bytes32[](dep.slots.length + 1);
            for (uint256 i = 0; i != dep.slots.length; i++) {
                newSlots[i] = dep.slots[i];
            }

            newSlots[dep.slots.length] = _slot;
            dep.slots = newSlots;

            return _c;
        }
    }

    function addConstraint(
        Dc memory _c,
        address _addr,
        bytes32 _slot,
        address _value
    ) internal pure returns (Dc memory) {
        _c.addConstraint(_addr, _slot, bytes32(uint256(uint160(_value))));
        return _c;
    }

    function addConstraint(
        Dc memory _c,
        address _addr,
        bytes32 _slot,
        bytes32 _value
    ) internal pure returns (Dc memory) {
        _c.addConstraint(_addr, _slot, _value, _value);
        return _c;
    }

    function addConstraint(
        Dc memory _c,
        address _addr,
        bytes32 _slot,
        bytes32 _minValue,
        bytes32 _maxValue
    ) internal pure returns (Dc memory) {
        unchecked {
            IEndorser.Dependency memory dep = _c._dependencyFor(_addr);

            IEndorser.Constraint memory constraint;
            bool exists;

            for (uint256 i = 0; i != dep.constraints.length; i++) {
                if (dep.constraints[i].slot == _slot) {
                    constraint = dep.constraints[i];
                    exists = true;
                    break;
                }
            }

            if (exists) {
                // If it exists we overlap the current constraint with the new values
                _minValue = bytes32(FixedPointMathLib.max(uint256(constraint.minValue), uint256(_minValue)));
                _maxValue = bytes32(FixedPointMathLib.min(uint256(constraint.maxValue), uint256(_maxValue)));
            }

            constraint.slot = _slot;
            constraint.minValue = _minValue;
            constraint.maxValue = _maxValue;

            if (constraint.minValue > constraint.maxValue) {
                revert("Constraint min value is greater than max value");
            }

            if (!exists) {
                // Add the new constraint to the dependency
                IEndorser.Constraint[] memory newConstraints = new IEndorser.Constraint[](dep.constraints.length + 1);
                for (uint256 i = 0; i != dep.constraints.length; i++) {
                    newConstraints[i] = dep.constraints[i];
                }

                newConstraints[dep.constraints.length] = constraint;
                dep.constraints = newConstraints;
            }

            return _c;
        }
    }

    function merge(
        Dc memory _c,
        Dc memory _next
    ) internal pure returns (Dc memory) {
        unchecked {
            _c._globalDependency.baseFee = _c._globalDependency.baseFee || _next._globalDependency.baseFee;
            _c._globalDependency.blobBaseFee =
                _c._globalDependency.blobBaseFee || _next._globalDependency.blobBaseFee;
            _c._globalDependency.chainId = _c._globalDependency.chainId || _next._globalDependency.chainId;
            _c._globalDependency.coinBase = _c._globalDependency.coinBase || _next._globalDependency.coinBase;
            _c._globalDependency.difficulty =
                _c._globalDependency.difficulty || _next._globalDependency.difficulty;
            _c._globalDependency.gasLimit = _c._globalDependency.gasLimit || _next._globalDependency.gasLimit;
            _c._globalDependency.number = _c._globalDependency.number || _next._globalDependency.number;
            _c._globalDependency.timestamp =
                _c._globalDependency.timestamp || _next._globalDependency.timestamp;
            _c._globalDependency.txOrigin = _c._globalDependency.txOrigin || _next._globalDependency.txOrigin;
            _c._globalDependency.txGasPrice =
                _c._globalDependency.txGasPrice || _next._globalDependency.txGasPrice;
            _c._globalDependency.maxBlockNumber =
                _c._globalDependency.maxBlockNumber.min(_next._globalDependency.maxBlockNumber);
            _c._globalDependency.maxBlockTimestamp =
                _c._globalDependency.maxBlockTimestamp.min(_next._globalDependency.maxBlockTimestamp);

            uint256 len = _next._dependencies.length;
            for (uint256 i = 0; i != len; i++) {
                IEndorser.Dependency memory nextDep = _next._dependencies[i];
                IEndorser.Dependency memory dep = _c._dependencyFor(nextDep.addr);

                dep.balance = dep.balance || nextDep.balance;
                dep.code = dep.code || nextDep.code;
                dep.nonce = dep.nonce || nextDep.nonce;
                dep.allSlots = dep.allSlots || nextDep.allSlots;

                uint256 slotLen = nextDep.slots.length;
                for (uint256 j = 0; j != slotLen; j++) {
                    _c.addSlotDependency(nextDep.addr, nextDep.slots[j]);
                }

                uint256 constraintLen = nextDep.constraints.length;
                for (uint256 j = 0; j != constraintLen; j++) {
                    IEndorser.Constraint memory constraint = nextDep.constraints[j];
                    _c.addConstraint(nextDep.addr, constraint.slot, constraint.minValue, constraint.maxValue);
                }
            }

            return _c;
        }
    }

    function setOperation(
        Dc memory _c,
        IEndorser.Operation memory _operation
    ) internal pure returns (Dc memory) {
        if (_c._hasOperation) {
            revert("Operation already set");
        }

        _c._operation = _operation;
        _c._hasOperation = true;
        return _c;
    }

    function getOperation(Dc memory _c) internal pure returns (IEndorser.Operation memory) {
        if (!_c._hasOperation) {
            revert("Operation not set");
        }

        return _c._operation;
    }


    function requireEntrypoint(
        Dc memory _c,
        address _entrypoint
    ) internal pure returns (Dc memory) {
        if (_entrypoint != _c.getOperation().entrypoint) {
            revert("Entrypoint mismatch: "
                .c(_entrypoint)
                .c(" != ".s())
                .c(_c.getOperation().entrypoint)
            );
        }

        return _c;
    }

    function requireInnerFixedGas(
        Dc memory _c,
        uint256 _innerFixedGas
    ) internal pure returns (Dc memory) {
        if (_innerFixedGas < _c.getOperation().fixedGas) {
            revert("Inner fixed gas is less than operation fixed gas: "
                .c(_innerFixedGas)
                .c(" < ".s())
                .c(_c.getOperation().fixedGas)
            );
        }

        return _c;
    }

    function requireInnerGasLimit(
        Dc memory _c,
        uint256 _innerGasLimit
    ) internal pure returns (Dc memory) {
        if (_innerGasLimit > _c.getOperation().gasLimit) {
            revert("Inner gas limit exceeds operation gas limit: "
                .c(_innerGasLimit)
                .c(" > ".s())
                .c(_c.getOperation().gasLimit)
            );
        }

        return _c;
    }

    function requireMaxFeePerGas(
        Dc memory _c,
        uint256 _maxFeePerGas
    ) internal pure returns (Dc memory) {
        if (_maxFeePerGas < _c.getOperation().maxFeePerGas) {
            revert("Max fee per gas is less than operation max fee per gas: "
                .c(_maxFeePerGas)
                .c(" < ".s())
                .c(_c.getOperation().maxFeePerGas)
            );
        }

        return _c;
    }

    function requireMaxPriorityFeePerGas(
        Dc memory _c,
        uint256 _maxPriorityFeePerGas
    ) internal pure returns (Dc memory) {
        if (_maxPriorityFeePerGas < _c.getOperation().maxPriorityFeePerGas) {
            revert("Max priority fee per gas is less than operation max priority fee per gas: "
                .c(_maxPriorityFeePerGas)
                .c(" < ".s())
                .c(_c.getOperation().maxPriorityFeePerGas)
            );
        }

        return _c;
    }

    function requireFeeToken(
        Dc memory _c,
        address _feeToken
    ) internal pure returns (Dc memory) {
        if (_feeToken != _c.getOperation().feeToken) {
            revert("Fee token mismatch: "
                .c(_feeToken)
                .c(" != ".s())
                .c(_c.getOperation().feeToken)
            );
        }

        return _c;
    }

    function requireScalingFactor(
        Dc memory _c,
        uint256 _scalingFactor
    ) internal pure returns (Dc memory) {
        if (_scalingFactor != _c.getOperation().feeScalingFactor) {
            revert("Scaling factor mismatch: "
                .c(_scalingFactor)
                .c(" != ".s())
                .c(_c.getOperation().feeScalingFactor)
            );
        }

        return _c;
    }

    function requireNormalizationFactor(
        Dc memory _c,
        uint256 _normalizationFactor
    ) internal pure returns (Dc memory) {
        if (_normalizationFactor != _c.getOperation().feeNormalizationFactor) {
            revert("Normalization factor mismatch: "
                .c(_normalizationFactor)
                .c(" != ".s())
                .c(_c.getOperation().feeNormalizationFactor)
            );
        }

        return _c;
    }

    function requireTrustedContext(Dc memory _c) internal pure returns (Dc memory) {
        if (_c.getOperation().hasUntrustedContext) {
            revert("Operation does not have untrusted context");
        }
        return _c;
    }

    function requireUntrustedContext(Dc memory _c) internal pure returns (Dc memory) {
        if (!_c.getOperation().hasUntrustedContext) {
            revert("Operation does not have untrusted context");
        }
        return _c;
    }
}
