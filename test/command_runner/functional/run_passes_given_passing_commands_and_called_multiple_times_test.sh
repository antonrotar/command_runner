#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

command_runner_add passing_command
command_runner_add another_passing_command
command_runner_run >/dev/null
expect_success $?

OUTPUT=$(command_runner_run)

expect_success $?
expect_log_contains "$(extract_logs "$OUTPUT")" "passing_command 0\nanother_passing_command 0"
expect_log_empty "$(extract_errors "$OUTPUT")"
expect_log_contains "$(extract_results "$OUTPUT")" "passing_command 0 PASSED\nanother_passing_command 0 PASSED"
