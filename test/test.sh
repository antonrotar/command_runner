set -euo pipefail

# This test executes all tests and verifies the overall repository status.

script_directory="$(dirname "$0")"

if ! "$script_directory/command_runner_test/test.sh"; then
  echo "Command runner tests should pass but fail."
  exit 1
fi

if ! "$script_directory/example_test/test.sh"; then
  echo "Example tests should pass but fail."
  exit 1
fi

echo "All tests passed."
