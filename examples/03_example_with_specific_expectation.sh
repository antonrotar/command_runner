#! /bin/bash -u

# This example adds and runs one failing command with specific expectation.
# The overall return value will be positive.

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

command_runner_add_with_expectation "echo Output from failing command;exit 1" 1

command_runner_run "$@"
