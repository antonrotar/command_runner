set -euo pipefail

# This example adds and runs multiple examples. One of them will fail.
# The overall return value will be negative.

script_directory="$(dirname "$0")"
source "$script_directory/../command_runner.sh"

command_runner_add ./$script_directory/01_simple_example.sh
command_runner_add ./$script_directory/02_failing_example.sh
command_runner_add_with_expectation ./$script_directory/02_failing_example.sh 1

command_runner_run "$@"
