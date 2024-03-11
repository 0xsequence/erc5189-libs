// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";
import { TestUtils } from "test/TestUtils.sol";

import { LibDc, Dc } from "contracts/LibDc.sol";
import { IEndorser } from "contracts/interfaces/IEndorser.sol";

contract LibDcTest is Test {
    using LibDc for Dc;

    function testDefaultCarrier() public {
        Dc memory carrier = LibDc.create();

        (
            bool ready,
            IEndorser.GlobalDependency memory globalDependency,
            IEndorser.Dependency[] memory dependencies
        ) = carrier.build();

        assertTrue(ready);
        assertTrue(!globalDependency.baseFee);
        assertTrue(!globalDependency.blobBaseFee);
        assertTrue(!globalDependency.chainId);
        assertTrue(!globalDependency.coinBase);
        assertTrue(!globalDependency.difficulty);
        assertTrue(!globalDependency.gasLimit);
        assertTrue(!globalDependency.number);
        assertTrue(!globalDependency.timestamp);
        assertTrue(!globalDependency.txOrigin);
        assertTrue(!globalDependency.txGasPrice);
        assertEq(globalDependency.maxBlockNumber, type(uint256).max);
        assertEq(globalDependency.maxBlockTimestamp, type(uint256).max);
        assertEq(dependencies.length, 0);
    }

    function testAddMaxBlockNumber(uint256 start, uint256 end) public {
        Dc memory carrier = LibDc.create();
        assertEq(carrier._globalDependency.maxBlockNumber, 0);
        assertFalse(carrier._explicitMaxBlockNumber);
        carrier.addMaxBlockNumber(start);
        assertEq(carrier._globalDependency.maxBlockNumber, start);
        assertTrue(carrier._explicitMaxBlockNumber);
        carrier.addMaxBlockNumber(end);
        assertTrue(carrier._explicitMaxBlockNumber);
    }

    function testAddMaxBlockTimestamp(uint256 start, uint256 end) public {
        Dc memory carrier = LibDc.create();
        carrier.addMaxBlockTimestamp(start);
        assertEq(carrier._globalDependency.maxBlockTimestamp, start);
        carrier.addMaxBlockTimestamp(end);
        assertEq(carrier._globalDependency.maxBlockTimestamp, TestUtils.min(start, end));
    }

    function testNoDuplicateDependencyForAddress(address addr) public {
        Dc memory carrier = LibDc.create();

        assertEq(carrier._dependencies.length, 0);

        carrier.addAllSlotsDependency(addr);
        assertEq(carrier._dependencies.length, 1);
        assertEq(carrier._dependencies[0].addr, addr);

        carrier.addBalanceDependency(addr);
        assertEq(carrier._dependencies.length, 1); // Still 1
        assertEq(carrier._dependencies[0].addr, addr);
    }

    function testAllSlotExclusivity(address addr, bytes32 slot) public {
        Dc memory carrier = LibDc.create();

        carrier.addSlotDependency(addr, slot);
        assertEq(carrier._dependencies.length, 1);
        assertEq(carrier._dependencies[0].addr, addr);
        assertEq(carrier._dependencies[0].slots.length, 1);
        assertEq(carrier._dependencies[0].slots[0], slot);

        // Removes slots
        carrier.addAllSlotsDependency(addr);
        assertEq(carrier._dependencies.length, 1);
        assertEq(carrier._dependencies[0].slots.length, 0);

        // Ignored
        carrier.addSlotDependency(addr, slot);
        assertEq(carrier._dependencies.length, 1);
        assertEq(carrier._dependencies[0].slots.length, 0);
    }

    function testConstraintOverlap(address addr, bytes32 slot, bytes32 min1, bytes32 max1, bytes32 min2, bytes32 max2)
        public
    {
        // Overall range valid
        bytes32 min = TestUtils.max(min1, min2);
        bytes32 max = TestUtils.min(max1, max2);
        vm.assume(min <= max);

        Dc memory carrier = LibDc.create();

        carrier.addConstraint(addr, slot, min1, max1);
        assertEq(carrier._dependencies.length, 1);
        assertEq(carrier._dependencies[0].addr, addr);
        assertEq(carrier._dependencies[0].constraints.length, 1);
        assertEq(carrier._dependencies[0].constraints[0].slot, slot);
        assertEq(carrier._dependencies[0].constraints[0].minValue, min1);
        assertEq(carrier._dependencies[0].constraints[0].maxValue, max1);

        carrier.addConstraint(addr, slot, min2, max2);
        assertEq(carrier._dependencies.length, 1);
        assertEq(carrier._dependencies[0].addr, addr);
        assertEq(carrier._dependencies[0].constraints.length, 1);
        assertEq(carrier._dependencies[0].constraints[0].slot, slot);
        assertEq(carrier._dependencies[0].constraints[0].minValue, min);
        assertEq(carrier._dependencies[0].constraints[0].maxValue, max);
    }

    function testContraintMinMaxError(address addr, bytes32 slot, bytes32 min, bytes32 max) public {
        vm.assume(min > max);

        Dc memory carrier = LibDc.create();
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
        bytes32 min = TestUtils.max(min1, min2);
        bytes32 max = TestUtils.min(max1, max2);
        vm.assume(min > max);

        Dc memory carrier = LibDc.create();
        carrier.addConstraint(addr, slot, min1, max1);

        vm.expectRevert();
        carrier.addConstraint(addr, slot, min2, max2);
    }
}
