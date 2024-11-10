set -euo pipefail

script_directory="$(dirname "$0")"

if ! "$script_directory/commands_test.sh"; then
  echo "Commands tests should pass but fail."
  exit 1
fi

if ! "$script_directory/example_test.sh"; then
  echo "Example tests should pass but fail."
  exit 1
fi

echo "All tests passed."
