#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../support/support.sh"

source_command_runner
command_runner_add arbitrary_command
OUTPUT=$(command_runner_run "-v" "arbitrary_unexpected_argument")

expect_failure $?
expect_log_contains "$OUTPUT" "command_runner_run -v arbitrary_unexpected_argument"
expect_log_contains "$OUTPUT" "Unexpected arguments. Please use -v or -s."
