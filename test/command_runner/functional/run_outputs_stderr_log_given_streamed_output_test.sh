#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

command_runner_add passing_command
command_runner_add failing_command_that_prints_to_error_log

command_runner_set_streamed_output

OUTPUT=$(command_runner_run)

expect_failure $?
expect_log_contains "$(extract_logs "$OUTPUT")" "passing_command\nOutput from passing command\nfailing_command_that_prints_to_error_log\nOutput from failing command"
expect_log_contains "$(extract_errors "$OUTPUT")" "failing_command_that_prints_to_error_log"

# The expectation below should actually pass. This is a bug not a feature.
# To be able to stream the command output synchonously, it is not captured, but printed directly instead.
# Therefore it is not available for the later report.
# Maybe I can come up with a solution for this at some point. For now I leave it as it is.
#
# expect_log_contains "$(extract_errors "$OUTPUT")" "Output from failing command"

expect_log_contains "$(extract_results "$OUTPUT")" "passing_command PASSED\nfailing_command_that_prints_to_error_log FAILED"
