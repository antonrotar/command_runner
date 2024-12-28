#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

command_runner_run >/dev/null
expect_success $?

OUTPUT=$(command_runner_run)

expect_success $?
expect_log_empty "$(extract_logs "$OUTPUT")"
expect_log_empty "$(extract_errors "$OUTPUT")"
expect_log_empty "$(extract_results "$OUTPUT")"
