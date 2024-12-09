#! /bin/bash -u

# This example adds and runs one failing and one passing command.
# The overall return value will be negative.

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

command_runner_add ./$SCRIPT_DIRECTORY/commands/failing_command.sh
command_runner_add ./$SCRIPT_DIRECTORY/commands/passing_command.sh

command_runner_run "$@"
