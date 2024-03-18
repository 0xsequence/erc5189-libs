//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import './IEndorser.sol';

interface IReceiptProvider {
  /// @notice Returns an event log filter that can be used to detect transactions that execute a given operation.
  /// @dev The filter is intended for eth_newFilter and eth_getLogs JSON-RPC requests.
  /// @dev Empty arrays returned in the topics array must be replaced with `null`.
  /// @param operation The operation to search for.
  /// @return _address The contract address to filter logs on.
  /// @return topics The event topics to filter logs on.
  function operationFilter(
    IEndorser.Operation calldata operation
  ) external pure returns (
    address _address,
    bytes32[][] memory topics
  );

  /// @notice Operation status
  enum Status {
    Unknown,
    Succeeded,
    Failed
  }

  /// @notice Event log
  struct Log {
    bytes32[] topics;
    bytes data;
  }

  /// @notice Returns an operation receipt derived from the event logs of a transaction that executes it.
  /// @param operation The operation to derive a receipt for.
  /// @param transactionLogs The logs of a transaction that executes the operation.
  /// @return status Whether the operation succeeded or failed.
  /// @return operationLogs The logs emitted specifically due to this operation.
  /// @return gasUsed The gas used specifically due to this operation.
  function operationReceipt(
    IEndorser.Operation calldata operation,
    Log[] calldata transactionLogs
  ) external pure returns (
    Status status,
    Log[] memory operationLogs,
    uint256 gasUsed
  );
}
