//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// solhint-disable no-inline-assembly

contract LibString {
    using LibString for string;

    function s(string memory _a) internal pure returns (string memory) {
        return _a;
    }

    function b(string memory _a) internal pure returns (bytes memory) {
        return bytes(_a);
    }

    function c(string memory _a, string memory _b) internal pure returns (string memory) {
        return _a.concat(_b);
    }

    function c(string memory _a, uint256 _v) internal pure returns (string memory) {
        return _a.concat(_v.toString());
    }

    function c(string memory _a, bytes32 _b) internal pure returns (string memory) {
        return _a.concat(uint256(_b).toHexString());
    }

    function c(string memory _a, address _b) internal pure returns (string memory) {
        return _a.concat(_b.toHexStringChecksummed());
    }

    function c(string memory _a, bytes memory _b) internal pure returns (string memory) {
        return _a.concat(_b.toHexString());
    }
}
