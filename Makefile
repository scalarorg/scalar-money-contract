.PHONY: test-all test-verbose test-files

test-all:
	forge test --match-path "tests/*.t.sol"

test-verbose:
	forge test --match-path "tests/*.t.sol" -vvvv

test-files:
	@if [ -z "$(files)" ]; then \
		echo "Usage: make test-files files='Foo Bar Baz'"; \
		echo "Example: make test-files files='Foo Bar'"; \
		exit 1; \
	fi
	@for file in $(files); do \
		echo "\nTesting $$file.t.sol:"; \
		forge test --match-path tests/$$file.t.sol -vvvv; \
	done
test-match:
	@if [ -z "$(match)" ]; then \
		echo "Usage: make test-match match='Foo Bar Baz'"; \
		echo "Example: make test-match match="test_SetFeeRate"      "; \
		exit 1; \
	fi
	@forge test --match-test $(match) -vvvv

.PHONY: bsctestnet sepolia
bsctestnet:
	./tools/deploy.sh bsctestnet
sepolia:
	./tools/deploy.sh

