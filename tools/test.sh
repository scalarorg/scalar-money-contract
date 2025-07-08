#!/bin/bash
set -e

# Load .env.test if it exists
if [ -f .env.test ]; then
  export $(grep -v '^#' .env.test | xargs)
fi

case "$1" in
  test-all)
    forge test --match-path "tests/*.t.sol"
    ;;
  test-verbose)
    forge test --match-path "tests/*.t.sol" -vvvv
    ;;
  test-files)
    if [ -z "$2" ]; then
      echo "Usage: $0 test-files 'Foo Bar Baz'"
      echo "Example: $0 test-files 'Foo Bar'"
      exit 1
    fi
    for file in $2; do
      echo "\nTesting $file.t.sol:"
      forge test --match-path tests/$file.t.sol -vvvv
    done
    ;;
  test-match)
    if [ -z "$2" ]; then
      echo "Usage: $0 test-match 'Foo Bar Baz'"
      echo "Example: $0 test-match 'test_SetFeeRate'"
      exit 1
    fi
    forge test --match-test "$2" -vvvv
    ;;
  *)
    echo "Unknown command. Use one of: test-all, test-verbose, test-files, test-match."
    exit 1
    ;;
esac 