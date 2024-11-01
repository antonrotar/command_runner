#!/bin/bash

# These tests are brittle. They prevented a refactoring now for a second time.
# On the third time, I will replace these tests with integration tests.

setup() {
  result=-1
  command_runner_reset
  command_runner_set_colored_output 0
  return 0
}
add_commands() {
  if [ "$#" -lt 2 ]; then
    return 0
  fi
  command_runner_add_specific "$1" "$2"
  shift
  shift
  add_commands "$@"
  return 0
}
check_result() {
  if [[ ! "$1" == "$2" ]]; then
    any_test_failed=1
    echo >&2 -e "$3" "\e[1;31mFAILED\e[0m"
    echo >&2 -e "Result:\n $1\n is not equal to\n $2"
  fi
  return 0
}
expect() {
  local hook="$1"
  local expected_result="$2"
  local test="$@"
  shift
  shift
  setup
  add_commands "$@"
  $hook
  check_result "$result" "$expected_result" "$test"
  return 0
}
exit_code() {
  command_runner_run_commands >/dev/null
  command_runner_validate
  result="$?"
  return 0
}
output() {
  result="$(command_runner_run_commands 2>&1)"
  return 0
}
verbose_output() {
  command_runner_set_verbose 1
  result="$(command_runner_run_commands 2>&1)"
  return 0
}
streamed_output() {
  command_runner_set_streamed 1
  result="$(command_runner_run_commands 2>&1)"
  return 0
}
errors_output() {
  command_runner_run_commands >/dev/null
  result="$(command_runner_print_errors 2>&1)"
  return 0
}
summary() {
  command_runner_run_commands >/dev/null
  result="$(command_runner_print_summary 2>&1)"
  return 0
}
exit_code_test_suite() {
  local pass=0
  local fail=1
  any_test_failed=0
  expect exit_code "$pass"
  expect exit_code "$pass" "exit 0" 0
  expect exit_code "$pass" "exit 42" 42
  expect exit_code "$fail" "exit 42" 0
  expect exit_code "$pass" "exit 0" 0 "exit 42" 42
  expect exit_code "$fail" "exit 0" 0 "exit 42" 0
  return "$any_test_failed"
}
output_test_suite() {
  local passing_output="Hello"
  local passing_command="echo $passing_output;exit 0"
  local passing_command_2="echo World;exit 0"
  local failing_output="Fail"
  local failing_command="echo $failing_output;exit 1"
  any_test_failed=0
  expect verbose_output "$(echo -e "$passing_command\n$passing_output")" "$passing_command" 0
  expect streamed_output "$(echo -e "$passing_command\n$passing_output")" "$passing_command" 0
  expect output "$passing_command" "$passing_command" 0
  expect output "$(echo -e "$passing_command\n$passing_command_2")" "$passing_command" 0 "$passing_command_2" 0
  expect errors_output "$(echo -e "Errors:")" "$passing_command" 0
  expect errors_output "$(echo -e "Errors:")" "$passing_command" 0 "$passing_command_2" 0
  expect errors_output "$(echo -e "Errors:\nError executing: $failing_command\nOutput:\n$failing_output\n")" "$failing_command" 0
  expect errors_output "$(echo -e "Errors:\nError executing: $failing_command\nOutput:\n$failing_output\n")" "$failing_command" 0 "$passing_command" 0
  return "$any_test_failed"
}
summary_test_suite() {
  local passing_command="echo Hello;exit 0"
  local failing_command="echo Hello;exit 42"
  any_test_failed=0
  expect summary "$(echo -e "\nOverall Results:")"
  expect summary "$(echo -e "\nOverall Results:\n$passing_command PASSED")" "$passing_command" 0
  expect summary "$(echo -e "\nOverall Results:\n$passing_command PASSED\n$failing_command FAILED")" "$passing_command" 0 "$failing_command" 0
  return "$any_test_failed"
}
nested_runner_test_suite() {
  any_test_failed=0
  script_using_runner="$script_directory/command_runner_test_client.sh"
  expect summary "$(echo -e "\nOverall Results:\n$script_using_runner FAILED")" "$script_using_runner" 0
  return "$any_test_failed"
}

setup_unit_tests() {
  script_directory="$(dirname "$0")"
  if ! source "$script_directory/../command_runner.sh"; then
    return 1
  fi
  return 0
}

run_unit_tests() {
  setup_unit_tests &&
    exit_code_test_suite &&
    output_test_suite &&
    summary_test_suite &&
    nested_runner_test_suite
}
