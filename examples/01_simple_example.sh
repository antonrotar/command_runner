#! /bin/bash -u

# Import command runner script.
SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

# Add two passing commands.
command_runner_add "echo Hello"
command_runner_add "echo World"

# Run commands. The overall result will be positive.
# Pass "$@" to the run function. It allows to run the whole
# example script like
# ./01_simple_example.sh -v
# to change output options and observe the results.
command_runner_run "$@"
