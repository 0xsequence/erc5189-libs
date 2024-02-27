# ERC5189 Libs

This repository contains libraries for interacting with [ERC-5189](https://eips.ethereum.org/EIPS/eip-5189) contracts.

## IEndorser

The `IEndorser` interface is an interface for ERC-5189 Endorsers.
For more information, see the [ERC-5189 specification](https://eips.ethereum.org/EIPS/eip-5189).

## LibDependencyCarrier

The `LibDependencyCarrier` library contains functions for recording dependencies by an ERC-5189 Endorser.

Create a `DependencyCarrier` with the `create()` function to ensure correct default settings (e.g. the `maxBlockNumber`).

```solidity
import {LibDependencyCarrier, DependencyCarrier} from "contracts/utils/LibDependencyCarrier.sol";

contract Endorser {
  using LibDependencyCarrier for DependencyCarrier;

  function _myFunction() internal {
    DependencyCarrier memory dc = LibDependencyCarrier.create();

    //...
  }
}
```

When adding dependencies, use the appropriate function. This ensures that overlapping dependencies are managed correctly.

```solidity
// These functions set the maximum value unless it is already set to a lower value
dc.addMaxBlockNumber(block.number + 1000);
dc.addMaxBlockTimestamp(block.timestamp + 1000);
```

When settings other `globalDependency` values, override by setting the value to `true` directly. Do not override with `false` as this will unset requirements set by other dependencies.

```solidity
dc.globalDependency.chainId = true;
```

For address specific dependencies, use the available functions to ensure no duplicate dependencies are created.

```solidity
dc.addBalanceDependency(0x1234);
dc.addCodeDependency(0x1234);
```

Similarly, for slot dependencies, use the available functions to ensure no duplicate dependencies are created. Setting slots is ignored if `allSlots` is set for the given address.

```solidity
dc.addSlotDependency(0x1234, 0x5678);
```

Some values cannot be determined on chain due to visibility restrictions. Use `contraints` to notify the ERC-5189 Bundler of the required values.

```solidity
dc.addConstraint(0x1234, 0x5678, 0x9abc); // Require specific value
dc.addConstraint(0x1234, 0xdefg, 0x0, 0x1); // Require value in range
```

The Endorser access the values in the `DependencyCarrier` when returning values for `isOperationReady()`.

```solidity
function isOperationReady(
  //...
) public view returns (bool readiness, GlobalDependency memory, Dependency[] memory) {
  //...
  return (readiness, dc.globalDependency, dc.dependencies);
}
```

## LibSlot

The `LibSlot` library contains functions for determining with storage mappings slots.

You can read about the storage layout of contracts in the [Solidity documentation](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html).

For a mapping, the slot is determined by the `keccak256` hash of the key and the storage slot. Find the mapping slot by interogating the storage layout of the contract.

For two dimensional mappings, the slot can be determined recursively.

```solidity
mapping(bytes32 => bytes32) public map;
mapping(bytes32 => mapping(bytes32 => bytes32)) public map2d;

map[0x5678] = 0xffff; // map at 0x0
LibSlot.getMappingStorageSlot(0x0, 0x5678);

map2d[0x5678][0x9abc] = 0xffff; // map2d at 0x1
LibSlot.getMappingStorageSlot(LibSlot.getMappingStorageSlot(0x1, 0x5678), 0x9abc);
```

## LibMath

The `LibMath` library contains optimised math functions for `min` and `max` calculations.

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test -vvv
```

### Format

Please run formatting before creating a pull request.

```shell
forge fmt
```

## License

All contracts in this repository are [UNLICENSED](./LICENSE).
