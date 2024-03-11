// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library TestUtils {
    function min(bytes32 _a, bytes32 _b) internal pure returns (bytes32) {
        return bytes32(min(uint256(_a), uint256(_b)));
    }

    function max(bytes32 _a, bytes32 _b) internal pure returns (bytes32) {
        return bytes32(max(uint256(_a), uint256(_b)));
    }

    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _a : _b;
    }
}
