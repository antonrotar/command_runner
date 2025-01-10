#! /bin/bash -u

source_command_runner() {
  SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
  source "$SCRIPT_DIRECTORY/../../command_runner.sh"

  # Disable colored output to allow exact string matching on output logs.
  command_runner_disable_colored_output
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

  local RETURN_VALUE="$1"

  if [ "$RETURN_VALUE" -ne 0 ]; then
    echo "Should pass, but fails."
    exit 1
  fi

  return 0
}

expect_failure() {
  _assert_argument_count $FUNCNAME 1 $#

  local RETURN_VALUE="$1"

  if [ "$RETURN_VALUE" -eq 0 ]; then
    echo "Should fail, but passes."
    exit 1
  fi

  return 0
}

expect_log_empty() {
  _assert_argument_count $FUNCNAME 1 $#

  local LOG="$1"

  # -n tests for "not empty"
  if [ -n "$LOG" ]; then
    echo "Expected log is empty. Actual log:"
    echo "$LOG"
    exit 1
  fi

  return 0
}

expect_log_contains() {
  _assert_argument_count $FUNCNAME 2 $#

  local LOG="$1"
  local EXPECTED_LOG="$2"

  # q prevents grep from printing the match, Pz is necessary for multiline matching.
  # Reference: https://stackoverflow.com/questions/152708/how-can-i-search-for-a-multiline-pattern-in-a-file
  echo "$LOG" | grep -qPz "$EXPECTED_LOG"

  # If grep finds a match the return value will be 0.
  if [ "$?" -ne 0 ]; then
    echo "Expected log contains:"
    echo -e "$EXPECTED_LOG"
    echo "Actual log:"
    echo -e "$LOG"
    exit 1
  fi

  return 0
}

expect_log_does_not_contain() {
  _assert_argument_count $FUNCNAME 2 $#

  local LOG="$1"
  local EXPECTED_LOG="$2"

  # q prevents grep from printing the match, Pz is necessary for multiline matching.
  # Reference: https://stackoverflow.com/questions/152708/how-can-i-search-for-a-multiline-pattern-in-a-file
  echo "$LOG" | grep -qPz "$EXPECTED_LOG"

  # If grep finds a match the return value will be 0.
  if [ "$?" -eq 0 ]; then
    echo "Expected log does not contain:"
    echo -e "$EXPECTED_LOG"
    echo "Actual log:"
    echo -e "$LOG"
    exit 1
  fi

  return 0
}

_extract_specific_logs() {
  _assert_argument_count $FUNCNAME 4 $#

  local LOG="$1"
  local RELEVANT_LOG="$2"
  local IRRELEVANT_LOG_1="$3"
  local IRRELEVANT_LOG_2="$4"

  local IS_RELEVANT_SECTION=false

  # Iterate over the multiline log and only echo the relevant section.
  while IFS= read -r LINE; do
    case "$LINE" in
    *"$RELEVANT_LOG"*)
      IS_RELEVANT_SECTION=true
      continue
      ;;
    *"$IRRELEVANT_LOG_1"* | *"$IRRELEVANT_LOG_2"*)
      IS_RELEVANT_SECTION=false
      continue
      ;;
    esac

    if [ "$IS_RELEVANT_SECTION" = true ]; then
      echo $LINE
    fi
  done <<<"$LOG"
}

extract_logs() {
  _assert_argument_count $FUNCNAME 1 $#

  local LOG="$1"

  _extract_specific_logs "$LOG" "Running commands:" "Errors:" "Results:"
}

extract_errors() {
  _assert_argument_count $FUNCNAME 1 $#

  local LOG="$1"

  _extract_specific_logs "$LOG" "Errors:" "Running commands:" "Results:"
}

extract_results() {
  _assert_argument_count $FUNCNAME 1 $#

  local LOG="$1"

  _extract_specific_logs "$LOG" "Results:" "Running commands:" "Errors:"
}

expect_log_does_not_contain_error_section() {
  _assert_argument_count $FUNCNAME 1 $#

  local LOG="$1"

  expect_log_does_not_contain "$LOG" "Errors:"
}

passing_command() {
  echo "Output from passing command"
  return 0
}

another_passing_command() {
  echo "Output from another passing command"
  return 0
}

failing_command() {
  echo "Output from failing command"
  return 1
}

failing_command_that_prints_to_stderr() {
  >&2 echo "Output from failing command"
  return 1
}

arbitrary_command() {
  passing_command
}

INJECTED_STATUS_CODE=0

inject_status_code() {
  _assert_argument_count $FUNCNAME 1 $#

  INJECTED_STATUS_CODE=$1
}

command_with_status_code_injection() {
  return $INJECTED_STATUS_CODE
}
