#! /bin/bash -u

# This example adds and runs two passing commands.
# The overall return value will be positive.

script_directory="$(dirname "$0")"
source "$script_directory/../command_runner.sh"

command_runner_add ./$script_directory/commands/passing_command.sh
command_runner_add ./$script_directory/commands/passing_command.sh

command_runner_run "$@"
