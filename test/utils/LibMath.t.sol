// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {LibMath} from "contracts/utils/LibMath.sol";

contract LibMathTest is Test {
    function testMinUint256(uint256 min, uint256 max) public {
        if (min < max) {
            assertEq(LibMath.min(min, max), min);
        } else {
            assertEq(LibMath.min(min, max), max);
        }
    }

    function testMaxUint256(uint256 min, uint256 max) public {
        if (min > max) {
            assertEq(LibMath.max(min, max), min);
        } else {
            assertEq(LibMath.max(min, max), max);
        }
    }

    function testMinBytes32(bytes32 min, bytes32 max) public {
        if (min < max) {
            assertEq(LibMath.min(min, max), min);
        } else {
            assertEq(LibMath.min(min, max), max);
        }
    }

    function testMaxBytes32(bytes32 min, bytes32 max) public {
        if (min > max) {
            assertEq(LibMath.max(min, max), min);
        } else {
            assertEq(LibMath.max(min, max), max);
        }
    }
}
