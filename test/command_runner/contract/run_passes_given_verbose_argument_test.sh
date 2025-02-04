#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

OUTPUT=$(command_runner_run "-v")

expect_success $?
expect_log_empty "$(extract_logs "$OUTPUT")"
expect_log_does_not_contain_error_section "$OUTPUT"
expect_log_empty "$(extract_results "$OUTPUT")"
