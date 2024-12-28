#! /bin/bash -u

# Import command runner script.
SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

command_runner_stop_on_failure

command_runner_add "echo Output from passing command"
command_runner_add "echo Output from failing command;/bin/false"
command_runner_add "echo Output from another failing command;/bin/false"
command_runner_add "echo Output from another passing command"

# Run commands. The overall result will be negative.
# Pass "$@" to the run function. It allows to run the whole
# example script like
# ./04_nested_example.sh -v
# to change output options and observe the results.
command_runner_run "$@"
