#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

command_runner_add passing_command
command_runner_add failing_command

command_runner_set_streamed 1

OUTPUT=$(command_runner_run "-v")

expect_failure $?
expect_log_contains "$(extract_logs "$OUTPUT")" "passing_command 0\nOutput from passing command\nfailing_command 0\nOutput from failing command"
expect_log_contains "$(extract_errors "$OUTPUT")" "Error executing: failing_command 0"
expect_log_contains "$(extract_errors "$OUTPUT")" "Output from failing command"
expect_log_contains "$(extract_results "$OUTPUT")" "passing_command 0 PASSED\nfailing_command 0 FAILED"
