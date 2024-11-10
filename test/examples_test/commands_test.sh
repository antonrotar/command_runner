set -euo pipefail

# This test verifies the execution of commands.

script_directory="$(dirname "$0")"

if ! "$script_directory/../../examples/commands/passing_command.sh"; then
  echo "Command should pass but fails."
  exit 1
fi

if "$script_directory/../../examples/commands/failing_command.sh"; then
  echo "Command should fail but passes."
  exit 1
fi

echo "All tests passed."
