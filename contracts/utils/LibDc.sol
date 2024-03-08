//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";
import { IEndorser } from "../interfaces/IEndorser.sol";

struct Dc {
    bool hasOperation;
    bool explicitMaxBlockNumber;
    bool explicitMaxBlockTimestamp;

    IEndorser.Operation operation;

    IEndorser.GlobalDependency globalDependency;
    IEndorser.Dependency[] dependencies;
}

library LibDc {
    using FixedPointMathLib for *;
    using LibDc for Dc;

    function create() internal pure returns (Dc memory _c) {}
    function create(IEndorser.Operation memory _operation) internal pure returns (Dc memory c) {
        c.operation = _operation;
        c.hasOperation = true;
    }

    function build(Dc memory _c) internal pure returns (bool, IEndorser.GlobalDependency memory, IEndorser.Dependency[] memory) {
        if (!_c.explicitMaxBlockNumber) {
            _c.globalDependency.maxBlockNumber = type(uint256).max;
        }

        if (!_c.explicitMaxBlockTimestamp) {
            _c.globalDependency.maxBlockTimestamp = type(uint256).max;
        }

        return (true, _c.globalDependency, _c.dependencies);
    }

    function addMaxBlockNumber(Dc memory _carrier, uint256 _maxBlockNumber) internal pure {
        if (!_carrier.explicitMaxBlockNumber) {
            _carrier.globalDependency.maxBlockNumber = _maxBlockNumber;
            _carrier.explicitMaxBlockNumber = true;
        } else {
            _carrier.globalDependency.maxBlockNumber = _carrier.globalDependency.maxBlockNumber.min(_maxBlockNumber);
        }

    }

    function addMaxBlockTimestamp(Dc memory _carrier, uint256 _maxBlockTimestamp) internal pure {
        if (!_carrier.explicitMaxBlockTimestamp) {
            _carrier.globalDependency.maxBlockTimestamp = _maxBlockTimestamp;
            _carrier.explicitMaxBlockTimestamp = true;
        } else {
            _carrier.globalDependency.maxBlockTimestamp = _carrier.globalDependency.maxBlockTimestamp.min(_maxBlockTimestamp);
        }
    }

    function dependencyFor(Dc memory _carrier, address _addr)
        internal
        pure
        returns (IEndorser.Dependency memory)
    {
        unchecked {
            for (uint256 i = 0; i != _carrier.dependencies.length; i++) {
                if (_carrier.dependencies[i].addr == _addr) {
                    return _carrier.dependencies[i];
                }
            }

            // We need to create a new dependency for this address, and add it to the carrier
            IEndorser.Dependency memory dep;
            dep.addr = _addr;

            IEndorser.Dependency[] memory newDeps = new IEndorser.Dependency[](_carrier.dependencies.length + 1);
            for (uint256 i = 0; i != _carrier.dependencies.length; i++) {
                newDeps[i] = _carrier.dependencies[i];
            }

            newDeps[_carrier.dependencies.length] = dep;
            _carrier.dependencies = newDeps;

            return dep;
        }
    }

    function addBalanceDependency(Dc memory _carrier, address _addr) internal pure {
        dependencyFor(_carrier, _addr).balance = true;
    }

    function addCodeDependency(Dc memory _carrier, address _addr) internal pure {
        dependencyFor(_carrier, _addr).code = true;
    }

    function addNonceDependency(Dc memory _carrier, address _addr) internal pure {
        dependencyFor(_carrier, _addr).nonce = true;
    }

    function addAllSlotsDependency(Dc memory _carrier, address _addr) internal pure {
        IEndorser.Dependency memory dep = dependencyFor(_carrier, _addr);
        dep.allSlots = true;
        // Slots and allSlots are mutually exclusive
        dep.slots = new bytes32[](0);
    }

    function addSlotDependency(Dc memory _carrier, address _addr, bytes32 _slot) internal pure {
        unchecked {
            IEndorser.Dependency memory dep = dependencyFor(_carrier, _addr);

            if (dep.allSlots) {
                // Slots and allSlots are mutually exclusive
                return;
            }

            for (uint256 i = 0; i != dep.slots.length; i++) {
                if (dep.slots[i] == _slot) {
                    return;
                }
            }

            bytes32[] memory newSlots = new bytes32[](dep.slots.length + 1);
            for (uint256 i = 0; i != dep.slots.length; i++) {
                newSlots[i] = dep.slots[i];
            }

            newSlots[dep.slots.length] = _slot;
            dep.slots = newSlots;
        }
    }

    function addConstraint(Dc memory _carrier, address _addr, bytes32 _slot, address _value)
        internal
        pure
    {
        _carrier.addConstraint(_addr, _slot, bytes32(uint256(uint160(_value))));
    }

    function addConstraint(Dc memory _carrier, address _addr, bytes32 _slot, bytes32 _value)
        internal
        pure
    {
        _carrier.addConstraint(_addr, _slot, _value, _value);
    }

    function addConstraint(
        Dc memory _carrier,
        address _addr,
        bytes32 _slot,
        bytes32 _minValue,
        bytes32 _maxValue
    ) internal pure {
        unchecked {
            IEndorser.Dependency memory dep = dependencyFor(_carrier, _addr);

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
                //solhint-disable-next-line custom-errors
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
        }
    }

    function merge(Dc memory _carrier, Dc memory _next) internal pure {
        unchecked {
            _carrier.globalDependency.baseFee = _carrier.globalDependency.baseFee || _next.globalDependency.baseFee;
            _carrier.globalDependency.blobBaseFee =
                _carrier.globalDependency.blobBaseFee || _next.globalDependency.blobBaseFee;
            _carrier.globalDependency.chainId = _carrier.globalDependency.chainId || _next.globalDependency.chainId;
            _carrier.globalDependency.coinBase = _carrier.globalDependency.coinBase || _next.globalDependency.coinBase;
            _carrier.globalDependency.difficulty =
                _carrier.globalDependency.difficulty || _next.globalDependency.difficulty;
            _carrier.globalDependency.gasLimit = _carrier.globalDependency.gasLimit || _next.globalDependency.gasLimit;
            _carrier.globalDependency.number = _carrier.globalDependency.number || _next.globalDependency.number;
            _carrier.globalDependency.timestamp =
                _carrier.globalDependency.timestamp || _next.globalDependency.timestamp;
            _carrier.globalDependency.txOrigin = _carrier.globalDependency.txOrigin || _next.globalDependency.txOrigin;
            _carrier.globalDependency.txGasPrice =
                _carrier.globalDependency.txGasPrice || _next.globalDependency.txGasPrice;
            _carrier.globalDependency.maxBlockNumber =
                _carrier.globalDependency.maxBlockNumber.min(_next.globalDependency.maxBlockNumber);
            _carrier.globalDependency.maxBlockTimestamp =
                _carrier.globalDependency.maxBlockTimestamp.min(_next.globalDependency.maxBlockTimestamp);

            uint256 len = _next.dependencies.length;
            for (uint256 i = 0; i != len; i++) {
                IEndorser.Dependency memory nextDep = _next.dependencies[i];
                IEndorser.Dependency memory dep = dependencyFor(_carrier, nextDep.addr);

                dep.balance = dep.balance || nextDep.balance;
                dep.code = dep.code || nextDep.code;
                dep.nonce = dep.nonce || nextDep.nonce;
                dep.allSlots = dep.allSlots || nextDep.allSlots;

                uint256 slotLen = nextDep.slots.length;
                for (uint256 j = 0; j != slotLen; j++) {
                    _carrier.addSlotDependency(nextDep.addr, nextDep.slots[j]);
                }

                uint256 constraintLen = nextDep.constraints.length;
                for (uint256 j = 0; j != constraintLen; j++) {
                    IEndorser.Constraint memory constraint = nextDep.constraints[j];
                    _carrier.addConstraint(nextDep.addr, constraint.slot, constraint.minValue, constraint.maxValue);
                }
            }
        }
    }
}
