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
     * @notice Checks if an operation is endorsed for execution.
     * @param entrypoint The entrypoint to of the operation.
     * @param data The data to send to the entrypoint.
     * @param endorserCallData Additional data for endorser processing.
     * @param gasLimit The gas limit for the operation.
     * @param maxFeePerGas The maximum fee per gas for the operation.
     * @param maxPriorityFeePerGas The maximum priority fee per gas for the operation.
     * @param feeToken The address of the ERC-20 token used to repay the sender. `address(0)` for the native token.
     * @param baseFeeScalingFactor The scaling factor for the base fee.
     * @param baseFeeNormalizationFactor The normalization factor for the base fee.
     * @param hasUntrustedContext Whether the operation has an untrusted context.
     * @return readiness Whether the operation is ready for execution.
     * @return globalDependency The global dependency of the operation.
     * @return dependencies The dependencies of the operation.
     */
    function isOperationReady(
        address entrypoint,
        bytes calldata data,
        bytes calldata endorserCallData,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        address feeToken,
        uint256 baseFeeScalingFactor,
        uint256 baseFeeNormalizationFactor,
        bool hasUntrustedContext
    ) external returns (bool readiness, GlobalDependency memory globalDependency, Dependency[] memory dependencies);

    /**
     * Returns the address this contract should be located at when performing simulations.
     * @return etchAddress The address this contract should be located at when performing simulations.
     */
    function etchAddress() external view returns (address payable etchAddress);
}
