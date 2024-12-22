#! /bin/bash -u

# Import command runner script.
SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

# Add one failing and one passing command.
# Note: /bin/false will do nothing but return a status code indicating failure.
# Check "man /bin/false" for details.
command_runner_add "echo Output from failing command;/bin/false"
command_runner_add "echo Output from passing command"

# Run commands. The overall result will be negative.
# Pass "$@" to the run function. It allows to run the whole
# example script like
# ./02_failing_example.sh -v
# to change output options and observe the results.
command_runner_run "$@"
