setup() {
  script_directory="$(dirname "$0")"
  if ! source "$script_directory/command_runner_unit_tests.sh"; then
    echo >&2 -e "\e[1;31mFAILED\e[0m"
    return 1
  fi
  if ! source "$script_directory/command_runner_api_tests.sh"; then
    echo >&2 -e "\e[1;31mFAILED\e[0m"
    return 1
  fi
  return 0
}

if setup && run_unit_tests && run_api_tests; then
  echo -e "\e[0;32mPASSED\e[0m"
  exit 0
else
  echo >&2 -e "\e[1;31mFAILED\e[0m"
  exit 1
fi
