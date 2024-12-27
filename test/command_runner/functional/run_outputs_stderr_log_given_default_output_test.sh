#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

command_runner_add passing_command
command_runner_add failing_command_that_prints_to_stderr

OUTPUT=$(command_runner_run)

expect_failure $?
expect_log_contains "$(extract_logs "$OUTPUT")" "passing_command\nfailing_command"
expect_log_contains "$(extract_errors "$OUTPUT")" "failing_command_that_prints_to_stderr\nOutput from failing command"
expect_log_contains "$(extract_results "$OUTPUT")" "passing_command PASSED\nfailing_command_that_prints_to_stderr FAILED"
