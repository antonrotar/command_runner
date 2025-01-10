#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

command_runner_add command_with_status_code_injection
inject_status_code 1
command_runner_run >/dev/null
expect_failure $?
inject_status_code 0

OUTPUT=$(command_runner_run)

expect_success $?
expect_log_contains "$(extract_logs "$OUTPUT")" "command_with_status_code_injection"
expect_log_does_not_contain_error_section "$OUTPUT"
expect_log_contains "$(extract_results "$OUTPUT")" "command_with_status_code_injection PASSED"
