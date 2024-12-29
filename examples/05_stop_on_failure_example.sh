#! /bin/bash -u

# Import command runner script.
SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner.sh"

# Configure the command runner to stop on failure.
# Per default it will continue on failure.
command_runner_stop_on_failure

# Add some passing and some failing commands.
# The first failing command will stop the execution of all subsequent commands.
# Run with "-v" to observe the behavior.
command_runner_add "echo Output from passing command"
command_runner_add "echo Output from failing command;/bin/false"
command_runner_add "echo Output from another failing command;/bin/false"
command_runner_add "echo Output from another passing command"

# Run commands. The overall result will be negative.
# Pass "$@" to the run function. It allows to run the whole
# example script like
# ./05_stop_on_failure_example.sh -v
# to change output options and observe the results.
command_runner_run "$@"
