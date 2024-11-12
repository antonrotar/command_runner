setup() {
  command_runner_reset
  command_runner_set_colored_output 0
}

command_runner_add_successful() {
  setup
  if ! command_runner_add "a"; then
    echo "command_runner_add_successful failed"
    return 1
  fi
  return 0
}

command_runner_fails_if_no_command() {
  setup
  if command_runner_add; then
    echo "command_runner_fails_if_no_command failed"
    return 1
  fi
  return 0
}

command_runner_add_fails_if_too_many_arguments() {
  setup
  if command_runner_add "a" "b" "c"; then
    echo "command_runner_add_fails_if_too_many_arguments failed"
    return 1
  fi
  return 0
}

command_runner_add_with_expectation_successful() {
  setup
  if ! command_runner_add_with_expectation "a" "b"; then
    echo "command_runner_add_with_expectation_successful failed"
    return 1
  fi
  return 0
}

command_runner_add_with_expectation_fails_if_not_enough_arguments() {
  setup
  if command_runner_add_with_expectation "b"; then
    echo "command_runner_add_with_expectation_fails_if_not_enough_arguments failed"
    return 1
  fi
  return 0
}

command_runner_add_with_expectation_fails_if_too_many_arguments() {
  setup
  if command_runner_add_with_expectation "a" "b" "c"; then
    echo "command_runner_add_with_expectation_fails_if_too_many_arguments failed"
    return 1
  fi
  return 0
}

command_runner_run_without_commands_successful() {
  setup
  if ! command_runner_run; then
    echo "command_runner_run_without_commands_successful failed"
    return 1
  fi
  return 0
}

command_runner_run_with_passing_commands_successful() {
  setup
  command_runner_add "exit 0"
  command_runner_add "exit 0"
  if ! command_runner_run; then
    echo "command_runner_run_with_passing_commands_successful failed"
    return 1
  fi
  return 0
}

command_runner_run_with_one_failing_command_fails() {
  setup
  command_runner_add "exit 0"
  command_runner_add "exit 1"
  if command_runner_run; then
    echo "command_runner_run_with_one_failing_command_fails failed"
    return 1
  fi
  return 0
}

command_runner_run_with_one_expectedly_failing_command_successful() {
  setup
  command_runner_add "exit 0"
  command_runner_add_with_expectation "exit 1" 1
  if ! command_runner_run; then
    echo "command_runner_run_with_one_expectedly_failing_command_successful failed"
    return 1
  fi
  return 0
}

command_runner_run_with_invalid_commands_fails() {
  setup
  command_runner_add
  if command_runner_run; then
    echo "command_runner_run_with_invalid_commands_fails failed"
    return 1
  fi
  return 0
}

command_runner_add_suite() {
  command_runner_add_successful &&
    command_runner_fails_if_no_command &&
    command_runner_add_fails_if_too_many_arguments
}

command_runner_add_with_expectation_suite() {
  command_runner_add_with_expectation_successful &&
    command_runner_add_with_expectation_fails_if_not_enough_arguments &&
    command_runner_add_with_expectation_fails_if_too_many_arguments
}

command_runner_run_suite() {
  command_runner_run_without_commands_successful &&
    command_runner_run_with_passing_commands_successful &&
    command_runner_run_with_one_failing_command_fails &&
    command_runner_run_with_one_expectedly_failing_command_successful
}

command_runner_run_invalid_commands_suite() {
  command_runner_run_with_invalid_commands_fails
}

setup_api_tests() {
  script_directory="$(dirname "$0")"
  if ! source "$script_directory/../../command_runner.sh"; then
    return 1
  fi
  return 0
}

run_api_tests() {
  setup_api_tests &&
    command_runner_add_suite &&
    command_runner_add_with_expectation_suite &&
    command_runner_run_suite &&
    command_runner_run_invalid_commands_suite
}
