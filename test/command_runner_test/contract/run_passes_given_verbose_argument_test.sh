#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../support/support.sh"

source_command_runner
command_runner_add arbitrary_command
OUTPUT=$(command_runner_run "-v")

expect_success $?
