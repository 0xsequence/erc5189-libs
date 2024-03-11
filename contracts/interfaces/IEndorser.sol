//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IEndorser {
    event UntrustedStarted();
    event UntrustedEnded();

    struct GlobalDependency {
        bool baseFee;
        bool blobBaseFee;
        bool chainId;
        bool coinBase;
        bool difficulty;
        bool gasLimit;
        bool number;
        bool timestamp;
        bool txOrigin;
        bool txGasPrice;
        uint256 maxBlockNumber;
        uint256 maxBlockTimestamp;
    }

    struct Constraint {
        bytes32 slot;
        bytes32 minValue;
        bytes32 maxValue;
    }

    struct Dependency {
        address addr;
        bool balance;
        bool code;
        bool nonce;
        bool allSlots;
        bytes32[] slots;
        Constraint[] constraints;
    }

    /**
     * @title Operation
     * @notice Represents an operation with its execution parameters and metadata for endorsement checks.
     * @dev This struct encapsulates all necessary details to execute and endorse an operation. It includes:
     * - `entrypoint`: The entrypoint address of the operation.
     * - `data`: The calldata to be sent to the entrypoint.
     * - `endorserCallData`: Additional data required for the endorser's processing.
     * - `fixedGas`: The fixed gas amount to be used for the operation.
     * - `gasLimit`: The maximum gas allowed for executing the operation.
     * - `maxFeePerGas`: The maximum fee per gas willing to be paid for the operation.
     * - `maxPriorityFeePerGas`: The maximum priority fee per gas to incentivize miners.
     * - `feeToken`: The ERC-20 token address used for transaction fee payment. Uses `address(0)` for the native token.
     * - `feeScalingFactor`: A factor to scale the base fee, adjusting operation cost in response to network congestion.
     * - `feeNormalizationFactor`: A factor for normalizing the base fee, facilitating fee estimation.
     * - `hasUntrustedContext`: Indicates if the operation is executed in a context that cannot be fully trusted.
     */
    struct Operation {
        address entrypoint;
        bytes data;
        bytes endorserCallData;
        uint256 fixedGas;
        uint256 gasLimit;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        address feeToken;
        uint256 feeScalingFactor;
        uint256 feeNormalizationFactor;
        bool hasUntrustedContext;
    }

    function isOperationReady(Operation calldata operation) external returns (
        bool readiness,
        GlobalDependency memory globalDependency,
        Dependency[] memory dependencies
    );

    struct Replacement {
        address oldAddr;
        address newAddr;
        SlotReplacement[] slots;
    }

    struct SlotReplacement {
        bytes32 slot;
        bytes32 value;
    }

    /**
     * @notice Returns the simulation settings the bundler should use when calling the endorser.
     * @return replacements The replacements to apply when calling isOperationReady.
     */
    function simulationSettings() external view returns (Replacement[] memory replacements);
}
