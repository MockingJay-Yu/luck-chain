# lacky-chain

# Getting Started

## Quickstart

```
git clone https://github.com/Cyfrin/foundry-smart-contract-lottery-cu
cd foundry-smart-contract-lottery-cu
forge build
```

## Library

```
forge install smartcontractkit/chainlink-brownie-contracts --no-commit
forge install transmissions11/solmate --no-commit
forge install Cyfrin/foundry-devops --no-commit
```

## Deploy

```
make deploy
```

## Testing
```
forge test
```

or

```
forge test --fork-url $SEPOLIA_RPC_URL
```

### Test Coverage

```
forge coverage
```
