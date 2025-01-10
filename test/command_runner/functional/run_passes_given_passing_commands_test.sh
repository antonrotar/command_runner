#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

command_runner_add passing_command
command_runner_add another_passing_command

OUTPUT=$(command_runner_run)

expect_success $?
expect_log_contains "$(extract_logs "$OUTPUT")" "passing_command\nanother_passing_command"
expect_log_does_not_contain_error_section "$OUTPUT"
expect_log_contains "$(extract_results "$OUTPUT")" "passing_command PASSED\nanother_passing_command PASSED"
