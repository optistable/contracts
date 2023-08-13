Here is the link to the other repositories for the Superhack hackathon:

Frontend: https://github.com/optistable/optistable-frontend
Optimism rollup: https://github.com/optistable/optimism
Optimism geth: https://github.com/optistable/op-geth

## Foundry


## Price feeds:

Mumbai USDC: 0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0
Mumbai USDT: 0x92C09849638959196E976289418e5973CC96d645
Mumbai DAI: 0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
