#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../support/support.sh"

"$SCRIPT_DIRECTORY/../../examples/01_simple_example.sh" >/dev/null
expect_success $?

"$SCRIPT_DIRECTORY/../../examples/02_failing_example.sh" >/dev/null
expect_failure $?

"$SCRIPT_DIRECTORY/../../examples/03_example_with_specific_expectation.sh" >/dev/null
expect_success $?

"$SCRIPT_DIRECTORY/../../examples/04_nested_example.sh" >/dev/null
expect_failure $?
