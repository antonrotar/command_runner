#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

command_runner_add passing_command
command_runner_add_with_expectation failing_command 1

OUTPUT=$(command_runner_run)

expect_success $?
expect_log_contains "$(extract_logs "$OUTPUT")" "passing_command 0\nfailing_command 1"
expect_log_empty "$(extract_errors "$OUTPUT")"
expect_log_contains "$(extract_results "$OUTPUT")" "passing_command 0 PASSED\nfailing_command 1 PASSED"
