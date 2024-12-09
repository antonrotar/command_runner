#! /bin/bash -u

# This example adds and runs multiple examples. One of them will fail.
# The overall return value will be negative.

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

command_runner_add ./$SCRIPT_DIRECTORY/01_simple_example.sh
command_runner_add ./$SCRIPT_DIRECTORY/02_failing_example.sh
command_runner_add_with_expectation ./$SCRIPT_DIRECTORY/02_failing_example.sh 1

command_runner_run "$@"
