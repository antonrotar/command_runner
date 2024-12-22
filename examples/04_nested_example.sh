#! /bin/bash -u

# Import command runner script.
SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

# Add command runner scripts as commands to a higher level command runner.
# The scripts will be run and evaluated just like regular commands.
# This can help to organize a more complex and large command suite.
command_runner_add ./$SCRIPT_DIRECTORY/01_simple_example.sh
command_runner_add ./$SCRIPT_DIRECTORY/02_failing_example.sh
command_runner_add_with_expectation ./$SCRIPT_DIRECTORY/02_failing_example.sh 1

# Run commands. The overall result will be negative.
# Pass "$@" to the run function. It allows to run the whole
# example script like
# ./04_nested_example.sh -v
# to change output options and observe the results.
command_runner_run "$@"
