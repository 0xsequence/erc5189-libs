//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library LibSlot {
    /**
     * Returns the storage location for a value at `key` in a mapping at `mappingSlot`.
     * @param mappingSlot The storage slot of the mapping
     * @param key The key of the mapping
     * @return valueSlot The storage location of the value
     */
    function getMappingStorageSlot(bytes32 mappingSlot, bytes32 key) internal pure returns (bytes32 valueSlot) {
        return keccak256(abi.encode(key, mappingSlot));
    }

    /**
     * Returns the storage location for a value at `key` in a mapping at `mappingSlot`.
     * @param mappingSlot The storage slot of the mapping
     * @param key The key of the mapping
     * @return valueSlot The storage location of the value
     */
    function getMappingStorageSlot(bytes32 mappingSlot, address key) internal pure returns (bytes32 valueSlot) {
        return keccak256(abi.encode(key, mappingSlot));
    }

    /**
     * Returns the storage location for a value at `key` in a mapping at `mappingSlot`.
     * @param mappingSlot The storage slot of the mapping
     * @param key The key of the mapping
     * @return valueSlot The storage location of the value
     */
    function getMappingStorageSlot(bytes32 mappingSlot, uint256 key) internal pure returns (bytes32 valueSlot) {
        return keccak256(abi.encode(key, mappingSlot));
    }
}
