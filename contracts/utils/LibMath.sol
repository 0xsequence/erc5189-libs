//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// solhint-disable no-inline-assembly

library LibMath {
    function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assembly {
            c := xor(a, mul(xor(a, b), lt(b, a)))
        }
    }

    function min(bytes32 a, bytes32 b) internal pure returns (bytes32 c) {
        assembly {
            c := xor(a, mul(xor(a, b), lt(b, a)))
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assembly {
            c := xor(a, mul(xor(a, b), gt(b, a)))
        }
    }

    function max(bytes32 a, bytes32 b) internal pure returns (bytes32 c) {
        assembly {
            c := xor(a, mul(xor(a, b), gt(b, a)))
        }
    }
}
