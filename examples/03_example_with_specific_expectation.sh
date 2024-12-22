#! /bin/bash -u

# Import command runner script.
SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

# Add a failing command but expect it to fail so it will be evaluated as "passed".
# Note: /bin/false will do nothing but return a status code indicating failure.
# Check "man /bin/false" for details.
command_runner_add_with_expectation "echo Output from failing command;/bin/false" 1

# Run commands. The overall result will be positive.
# Pass "$@" to the run function. It allows to run the whole
# example script like
# ./03_example_with_specific_expectation.sh -v
# to change output options and observe the results.
command_runner_run "$@"
