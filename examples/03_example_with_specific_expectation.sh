set -euo pipefail

# This example adds and runs one failing command with specific expectation.
# The overall return value will be positive.

script_directory="$(dirname "$0")"
source "$script_directory/../command_runner.sh"

command_runner_add_with_expectation ./$script_directory/commands/failing_command.sh 1

command_runner_run "$@"
