# ERC5189 Libs

This repository contains libraries for interacting with [ERC-5189](https://eips.ethereum.org/EIPS/eip-5189) contracts.

## IEndorser

The `IEndorser` interface is an interface for ERC-5189 Endorsers.
For more information, see the [ERC-5189 specification](https://eips.ethereum.org/EIPS/eip-5189).

## IReceiptProvider

The IReceiptProvider is an additional interface for ERC-5189 endorsers to provide operation receipts.
For more information, see the [ERC-7655 specification](https://eips.ethereum.org/EIPS/eip-7655).

## LibDc

The `LibDc` library contains functions for constructing dependency lists for ERC-5189 Endorsers, it uses a builder pattern that simplifies the process of creating dependencies.

Create a `Dc` (DependencyCarrier) with the `create()`, an optional `IEndorser.Operation` can be passed to it, this will allow the library to also perform assertions on the operation.

```solidity
import { Dc, LibDc } from "contracts/LibDc.sol";

contract Endorser {
  using LibDc for Dc;

  function _myFunction() internal {
    Dc memory dc = LibDc.create();

    //...
  }
}
```

You can define global dependencies using the available functions.

```solidity
// These can only be set once
dc.addBaseFee();
dc.addBlobBaseFee();
dc.addChainId();
dc.addCoinBase();
dc.addDifficulty();
dc.addGasLimit();
dc.addNumber();
dc.addTimestamp();
dc.addTxOrigin();
dc.addTxGasPrice();

// These functions set the maximum value unless it is already set to a lower value
dc.addMaxBlockNumber(block.number + 1000);
dc.addMaxBlockTimestamp(block.timestamp + 1000);
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

The `build()` method will return the return arguments for `isOperationReady()`.

```solidity
function isOperationReady(
  //...
) public view returns (bool readiness, GlobalDependency memory, Dependency[] memory) {
  //...
  return dc.build();
}
```

### Chaining changes

The library supports the builder pattern, allowing for chaining changes. This pattern is entirely optional, as the `Dc` is modified in place.

```solidity
Dc memory dc = LibDc.create()
  .addBaseFee()
  .addBlobBaseFee()
  .addChainId()
  .addCoinBase()
  .addDifficulty()
  .addGasLimit()
  .addNumber()
  .addTimestamp()
  .addTxOrigin()
  .addTxGasPrice()
  .addMaxBlockNumber(block.number + 1000)
  .addMaxBlockTimestamp(block.timestamp + 1000)
  .addBalanceDependency(0x1234)
  .addCodeDependency(0x1234)
  .addSlotDependency(0x1234, 0x5678)
  .addConstraint(0x1234, 0x5678, 0x9abc)
  .addConstraint(0x1234, 0xdefg, 0x0, 0x1);
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

## LibString

The `LibString` allows for creating verbose string errors, for debugging purposes. These verbose strings can be used to generate detailed revert messages, which can be helpful when building complex endorser contracts.

```solidity
import { LibString } from "contracts/LibString.sol";

contract Example {
  using LibString for *;

  function example() public {
    // Concatenate strings
    // "Hola mundo!"
    string memory s1 = "Hola ".c("mundo!".s());

    // Concatenate uints and strings
    // "Hola 123!"
    string memory s2 = "Hola ".c(123).c("!");

    // Concatenate bytes32 and strings
    // Hex formatted: df5f697d36135c1a2b807e8cdd39a4c3a6e9aa5295c6f750a0d674daf840617d
    string memory s3 = "Hex formatted: ".c(bytes32(0xdf5f697d36135c1a2b807e8cdd39a4c3a6e9aa5295c6f750a0d674daf840617d));

    // Concatenate address and strings
    // "Address: 0x0xe28c4384F57e38775B288C5becDb3B28f2b0AEdb"
    string memory s4 = "Address: ".c(address(0xe28c4384F57e38775B288C5becDb3B28f2b0AEdb));

    // Concatenate byte arrays and strings
    // "Bytes: 0x1234"
    string memory s5 = "Bytes: ".c(hex"1234");
  }
}
```

> Notice that concatenating two strings requires calling `.s()` on the argument, this is to avoid ambiguity when concatenating strings and other types. The `solc` compiler will not allow concatenating two strings without an explicit conversion.

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
