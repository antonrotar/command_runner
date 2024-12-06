#! /bin/bash -u

source_command_runner() {
  SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
  source "$SCRIPT_DIRECTORY/../../../command_runner.sh"
}

_assert_argument_count() {
  local FUNCTION_NAME="$1"
  local EXPECTED_ARGUMENT_COUNT="$2"
  local ACTUAL_ARGUMENT_COUNT="$3"

  if [ "$ACTUAL_ARGUMENT_COUNT" -ne "$EXPECTED_ARGUMENT_COUNT" ]; then
    echo "$FUNCTION_NAME: Please provide exactly $EXPECTED_ARGUMENT_COUNT instead of $ACTUAL_ARGUMENT_COUNT argument(s)."
    exit 1
  fi

  return 0
}

expect_success() {
  _assert_argument_count $FUNCNAME 1 $#

  if [ "$1" -ne 0 ]; then
    echo "Should pass, but fails."
    exit 1
  fi

  return 0
}

expect_failure() {
  _assert_argument_count $FUNCNAME 1 $#

  if [ "$1" -eq 0 ]; then
    echo "Should fail, but passes."
    exit 1
  fi

  return 0
}

expect_log_empty() {
  _assert_argument_count $FUNCNAME 1 $#

  if [ ! -z "$1" ]; then
    echo "Expected log is empty. Actual log:"
    echo "$1"
    exit 1
  fi

  return 0
}

expect_log_contains() {
  _assert_argument_count $FUNCNAME 2 $#

  echo "$1" | grep -q "$2"

  if [ "$?" -ne 0 ]; then
    echo "Expected log contains:"
    echo "$2"
    echo "Actual log:"
    echo "$1"
    exit 1
  fi

  return 0
}

passing_command() {
  echo "Output from passing command"
  return 0
}

failing_command() {
  echo "Output from failing command"
  return 1
}

arbitrary_command() {
  passing_command
}
