.PHONY: bsctestnet sepolia
bsctestnet:
	./tools/deploy.sh bsctestnet
sepolia:
	./tools/deploy.sh
sepolia2:
	contract-deployer --config deploy.toml

