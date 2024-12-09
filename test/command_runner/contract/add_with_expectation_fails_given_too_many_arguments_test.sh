#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

OUTPUT=$(command_runner_add_with_expectation arbitrary_command 0 "arbitrary_unexpected_argument")

expect_failure $?
expect_log_contains "$OUTPUT" "command_runner_add_with_expectation arbitrary_command 0 arbitrary_unexpected_argument"
expect_log_contains "$OUTPUT" "Please provide exactly one expectation."
