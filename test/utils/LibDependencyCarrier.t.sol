// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {LibDependencyCarrier, DependencyCarrier} from "contracts/utils/LibDependencyCarrier.sol";
import {LibMath} from "contracts/utils/LibMath.sol";

contract LibDependencyCarrierTest is Test {
    using LibDependencyCarrier for DependencyCarrier;

    function testDefaultCarrier() public {
        DependencyCarrier memory carrier = LibDependencyCarrier.create();
        assertTrue(!carrier.globalDependency.baseFee);
        assertTrue(!carrier.globalDependency.blobBaseFee);
        assertTrue(!carrier.globalDependency.chainId);
        assertTrue(!carrier.globalDependency.coinBase);
        assertTrue(!carrier.globalDependency.difficulty);
        assertTrue(!carrier.globalDependency.gasLimit);
        assertTrue(!carrier.globalDependency.number);
        assertTrue(!carrier.globalDependency.timestamp);
        assertTrue(!carrier.globalDependency.txOrigin);
        assertTrue(!carrier.globalDependency.txGasPrice);
        assertEq(carrier.globalDependency.maxBlockNumber, type(uint256).max);
        assertEq(carrier.globalDependency.maxBlockTimestamp, type(uint256).max);
        assertEq(carrier.dependencies.length, 0);
    }

    function testAddMaxBlockNumber(uint256 start, uint256 end) public {
        DependencyCarrier memory carrier = LibDependencyCarrier.create();
        carrier.addMaxBlockNumber(start);
        assertEq(carrier.globalDependency.maxBlockNumber, start);
        carrier.addMaxBlockNumber(end);
        assertEq(carrier.globalDependency.maxBlockNumber, LibMath.min(start, end));
    }

    function testAddMaxBlockTimestamp(uint256 start, uint256 end) public {
        DependencyCarrier memory carrier = LibDependencyCarrier.create();
        carrier.addMaxBlockTimestamp(start);
        assertEq(carrier.globalDependency.maxBlockTimestamp, start);
        carrier.addMaxBlockTimestamp(end);
        assertEq(carrier.globalDependency.maxBlockTimestamp, LibMath.min(start, end));
    }

    function testNoDuplicateDependencyForAddress(address addr) public {
        DependencyCarrier memory carrier = LibDependencyCarrier.create();

        assertEq(carrier.dependencies.length, 0);

        carrier.addAllSlotsDependency(addr);
        assertEq(carrier.dependencies.length, 1);
        assertEq(carrier.dependencies[0].addr, addr);

        carrier.addBalanceDependency(addr);
        assertEq(carrier.dependencies.length, 1); // Still 1
        assertEq(carrier.dependencies[0].addr, addr);
    }

    function testAllSlotExclusivity(address addr, bytes32 slot) public {
        DependencyCarrier memory carrier = LibDependencyCarrier.create();

        carrier.addSlotDependency(addr, slot);
        assertEq(carrier.dependencies.length, 1);
        assertEq(carrier.dependencies[0].addr, addr);
        assertEq(carrier.dependencies[0].slots.length, 1);
        assertEq(carrier.dependencies[0].slots[0], slot);

        // Removes slots
        carrier.addAllSlotsDependency(addr);
        assertEq(carrier.dependencies.length, 1);
        assertEq(carrier.dependencies[0].slots.length, 0);

        // Ignored
        carrier.addSlotDependency(addr, slot);
        assertEq(carrier.dependencies.length, 1);
        assertEq(carrier.dependencies[0].slots.length, 0);
    }

    function testConstraintOverlap(address addr, bytes32 slot, bytes32 min1, bytes32 max1, bytes32 min2, bytes32 max2)
        public
    {
        // Overall range valid
        bytes32 min = LibMath.max(min1, min2);
        bytes32 max = LibMath.min(max1, max2);
        vm.assume(min <= max);

        DependencyCarrier memory carrier = LibDependencyCarrier.create();

        carrier.addConstraint(addr, slot, min1, max1);
        assertEq(carrier.dependencies.length, 1);
        assertEq(carrier.dependencies[0].addr, addr);
        assertEq(carrier.dependencies[0].constraints.length, 1);
        assertEq(carrier.dependencies[0].constraints[0].slot, slot);
        assertEq(carrier.dependencies[0].constraints[0].minValue, min1);
        assertEq(carrier.dependencies[0].constraints[0].maxValue, max1);

        carrier.addConstraint(addr, slot, min2, max2);
        assertEq(carrier.dependencies.length, 1);
        assertEq(carrier.dependencies[0].addr, addr);
        assertEq(carrier.dependencies[0].constraints.length, 1);
        assertEq(carrier.dependencies[0].constraints[0].slot, slot);
        assertEq(carrier.dependencies[0].constraints[0].minValue, min);
        assertEq(carrier.dependencies[0].constraints[0].maxValue, max);
    }

    function testContraintMinMaxError(address addr, bytes32 slot, bytes32 min, bytes32 max) public {
        vm.assume(min > max);

        DependencyCarrier memory carrier = LibDependencyCarrier.create();
        vm.expectRevert();
        carrier.addConstraint(addr, slot, min, max);
    }

    function testContraintOverlapMinMaxError(
        address addr,
        bytes32 slot,
        bytes32 min1,
        bytes32 max1,
        bytes32 min2,
        bytes32 max2
    ) public {
        // First range valid
        vm.assume(min1 <= max1);

        // Overall range invalid
        bytes32 min = LibMath.max(min1, min2);
        bytes32 max = LibMath.min(max1, max2);
        vm.assume(min > max);

        DependencyCarrier memory carrier = LibDependencyCarrier.create();
        carrier.addConstraint(addr, slot, min1, max1);

        vm.expectRevert();
        carrier.addConstraint(addr, slot, min2, max2);
    }
}
