#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../../support/support.sh"

source_command_runner

OUTPUT=$(command_runner_set_verbose_output)

expect_success $?
expect_log_empty "$OUTPUT"
