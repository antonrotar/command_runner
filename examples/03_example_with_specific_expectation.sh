#! /bin/bash -u

# This example adds and runs one failing command with specific expectation.
# The overall return value will be positive.

SCRIPT_DIRECTORY="$(dirname "$0")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

command_runner_add_with_expectation ./$SCRIPT_DIRECTORY/commands/failing_command.sh 1

command_runner_run "$@"
