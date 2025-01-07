#! /bin/bash -u

# Import command runner script.
SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

# This example demonstrates the usage of the short aliases:
# cra=command_runner_add
# crr=command_runner_run

# Add one failing and one passing command.
# Note: /bin/false will do nothing but return a status code indicating failure.
# Check "man /bin/false" for details.
cra "echo Output from failing command;/bin/false"
cra "echo Output from passing command"

# Run commands. The overall result will be negative.
# Pass "$@" to the run function. It allows to run the whole
# example script like
# ./06_short_aliases_example.sh -v
# to change output options and observe the results.
crr "$@"
