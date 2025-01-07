#! /bin/bash -u

SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../support/support.sh"
EXAMPLES_DIRECTORY="$SCRIPT_DIRECTORY/../../examples"

"$EXAMPLES_DIRECTORY/01_simple_example.sh" >/dev/null
expect_success $?

"$EXAMPLES_DIRECTORY/02_failing_example.sh" >/dev/null
expect_failure $?

"$EXAMPLES_DIRECTORY/03_example_with_specific_expectation.sh" >/dev/null
expect_success $?

"$EXAMPLES_DIRECTORY/04_nested_example.sh" >/dev/null
expect_failure $?

"$EXAMPLES_DIRECTORY/05_stop_on_failure_example.sh" >/dev/null
expect_failure $?

# Simple smoke test that all examples have a corresponding test.
NUMBER_OF_TESTS=5
NUMBER_OF_EXAMPLES=$(ls $EXAMPLES_DIRECTORY/*.sh | wc -l)
if [ "$NUMBER_OF_TESTS" -ne "$NUMBER_OF_EXAMPLES" ]; then
  echo "Number of tests ($NUMBER_OF_TESTS) does not match number of examples ($NUMBER_OF_EXAMPLES)."
  exit 1
fi
