<!--
parent:
  order: false
-->

<div align="center">
  <h1> Fishcake Contracts Repo</h1>
</div>

<div align="center">
  <a href="https://github.com/FishcakeLab/fishcake-contracts/releases/latest">
    <img alt="Version" src="https://img.shields.io/github/tag/FishcakeLab/fishcake-contracts.svg" />
  </a>
  <a href="https://github.com/FishcakeLab/fishcake-contracts/blob/main/LICENSE">
    <img alt="License: Apache-2.0" src="https://img.shields.io/github/license/FishcakeLab/fishcake-contracts.svg" />
  </a>
</div>

Fishcake Contracts Project

## Installation

For prerequisites and detailed build instructions please read the [Installation](https://github.com/FishcakeLab/fishcake-contracts/) instructions. Once the dependencies are installed, run:

```bash
git submodule update --init --recursive --remote
```

Or check out the latest [release](https://github.com/FishcakeLab/fishcake-contracts).

##  Test And Depoly

### test
```
forge test 
```

### Depoly

```
forge script script/Deployer.s.sol:DeployerScript --rpc-url $RPC_URL --private-key $PRIVKEY

```


## Community


## Contributing

Looking for a good place to start contributing? Check out some [`good first issues`](https://github.com/FishcakeLab/fishcake-contracts/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22).

For additional instructions, standards and style guides, please refer to the [Contributing](./CONTRIBUTING.md) document.
