#! /bin/bash -u

# BSD 3-Clause License
#
# Copyright (c) 2024, Anton Rotar
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Usage.
#
## source "$COMMAND_RUNNER_DIRECTORY/command_runner.sh"
##
## command_runner_add "echo Hello"
## command_runner_add "echo World"
##
## command_runner_run
#
# For further details please check the "Public API" section of this script.

# Implementation.
#
# Variables and states.
COMMANDS=()              # Commands to be executed collected via the "add" functions.
EXPECTED_STATUS_CODES=() # Optional expected status codes. 0 is set as default expectation.
SHOULD_STOP_ON_FAILURE=0 # Will stop execution after first failure. Per default all commands are executed.
COMMAND_PASSED=0         # Result for command if status code was as expected.
COMMAND_FAILED=1         # Result for command if status code was not as expected.
COMMAND_SKIPPED=2        # Result for command if command was skipped.
RESULTS=()               # Results of the commands after execution and evaluation.
OUTPUTS=()               # Output logs of the commands after execution.

# Output options.
COLORED_OUTPUT=1  # Use colors in command runner output.
REGULAR_OUTPUT=0  # Print failed command outputs only.
VERBOSE_OUTPUT=1  # Print all command outputs AFTER execution.
STREAMED_OUTPUT=2 # Print all command outputs DURING execution.
CURRENT_OUTPUT=$REGULAR_OUTPUT

# Color codes.
WHITE="0;0"
NORMAL_RED="0;31"
BOLD_RED="1;31"
NORMAL_GREEN="0;32"
NORMAL_CYAN="0;36"
BOLD_LIGHT_CYAN="1;96"
NORMAL_LIGHT_YELLOW="0;93"

# Private functions.
#
# Helper function to reset states. Make sure all states accumulated in command_runner_run are reset.
_reset_states() {
  RESULTS=()
  OUTPUTS=()
}

# Helper function for contract guard clause. Prints error log and exits the script.
_fail_contract() {
  local FUNCTION_NAME="$1"
  local ERROR_LOG="$2"
  shift
  shift

  echo -e "$(_print_failed)" "$FUNCTION_NAME" "$@"
  echo $ERROR_LOG

  exit 1
}

# Helper function for command_runner_run argument handling.
# Verifies that either no option or one of [-v, -s] is set.
_set_output_options() {
  local CALLING_FUNCTION="$1"
  shift

  if [ "$#" -eq 1 ]; then
    case "$1" in
    "-v") command_runner_set_verbose_output ;;
    "-s") command_runner_set_streamed_output ;;
    *) _fail_contract $CALLING_FUNCTION "Unexpected argument. Please use -v or -s." "$@" ;;
    esac
  elif [ "$#" -gt 1 ]; then
    _fail_contract $CALLING_FUNCTION "Unexpected arguments. Please use -v or -s." "$@"
  fi

  return 0
}

# Prints given output in color if enabled.
_print_colored() {
  local COLOR="$1"
  shift

  if [ "$COLORED_OUTPUT" -eq 1 ]; then
    echo -e "\e["$COLOR"m$@\e[0m"
  else
    echo "$@"
  fi

  return 0
}

_print_command() {
  local COLOR="$1"
  local COMMAND="$2"
  local EXPECTATION="$3"

  if [ "$EXPECTATION" -eq 0 ]; then
    _print_colored "$COLOR" "$COMMAND"
  else
    _print_colored "$COLOR" "$COMMAND" "$EXPECTATION"
  fi

  return 0
}

_print_info() {
  local INFO_MESSAGE="$1"

  _print_colored "$BOLD_LIGHT_CYAN" "$INFO_MESSAGE"

  return 0
}

_print_passed() {
  _print_colored "$NORMAL_GREEN" "PASSED"

  return 0
}

_print_failed() {
  _print_colored "$BOLD_RED" "FAILED"

  return 0
}

_print_skipped() {
  _print_colored "$NORMAL_LIGHT_YELLOW" "SKIPPED"

  return 0
}

# Fill arrays with valid values even if command is skipped.
# This way they will have a consistent size after execution.
_skip_command_and_store_result() {
  RESULTS+=($COMMAND_SKIPPED)
  OUTPUTS+=("")
}

# This is the main function of the whole script.
# Commands are executed here.
# The output is printed given the different output options.
_run_command_and_store_result() {
  local COMMAND="$1"
  local EXPECTED_STATUS_CODE="$2"
  local STATUS_CODE=0
  local OUTPUT=""
  local REDIRECT_STDERR_TO_STDOUT="2>&1" # Capture all outputs of executed commands.

  if [ "$CURRENT_OUTPUT" -eq "$STREAMED_OUTPUT" ]; then
    # This allows synchronous printing. This is helpful if you want to observe the progress of long running commands.
    # Ideally the output would still be stored in addition to printing it directly.
    # I didn't find a way to accomplish that unfortunately.
    eval "$COMMAND" "$REDIRECT_STDERR_TO_STDOUT"
    STATUS_CODE=$?
  else
    OUTPUT="$(eval "$COMMAND" "$REDIRECT_STDERR_TO_STDOUT")"
    STATUS_CODE=$?

    if [ "$CURRENT_OUTPUT" -eq "$VERBOSE_OUTPUT" ]; then
      echo "$OUTPUT"
    fi
  fi

  if [ "$STATUS_CODE" -eq "$EXPECTED_STATUS_CODE" ]; then
    RESULTS+=($COMMAND_PASSED)
  else
    RESULTS+=($COMMAND_FAILED)
  fi

  OUTPUTS+=("$OUTPUT")

  return 0
}

# Run all stored commands, print them and store the results.
_run_commands() {
  _print_info "Running commands:"

  local RESULTING_STATUS_CODE=0
  local SKIP_REMAINING_COMMANDS=0

  for i in "${!COMMANDS[@]}"; do
    _print_command "$NORMAL_CYAN" "${COMMANDS[$i]}" "${EXPECTED_STATUS_CODES[$i]}"

    if [ "$SKIP_REMAINING_COMMANDS" -eq 1 ]; then
      _skip_command_and_store_result
    else
      _run_command_and_store_result "${COMMANDS[$i]}" "${EXPECTED_STATUS_CODES[$i]}"
    fi

    if [ "${RESULTS[-1]}" -eq "$COMMAND_FAILED" ]; then

      RESULTING_STATUS_CODE=1 # Mark the overall result as FAILED.

      if [ "$SHOULD_STOP_ON_FAILURE" -eq 1 ]; then
        _print_colored "$NORMAL_LIGHT_YELLOW" "COMMAND FAILED AND STOP ON FAILURE IS ENABLED. SKIPPING REMAINING COMMANDS."
        SKIP_REMAINING_COMMANDS=1
      fi
    fi
  done

  return $RESULTING_STATUS_CODE
}

# This function prints the output of all failed commands.
_print_errors() {
  local IS_HEADER_PRINTED=0

  for i in "${!RESULTS[@]}"; do
    if [ "${RESULTS[$i]}" -eq "$COMMAND_FAILED" ]; then
      # Print header once if any error occurred.
      if [ "$IS_HEADER_PRINTED" -ne 1 ]; then
        echo # Empty line for better readability.
        _print_info "Errors:"
        IS_HEADER_PRINTED=1
      fi

      _print_command "$NORMAL_RED" "${COMMANDS[$i]}" "${EXPECTED_STATUS_CODES[$i]}"
      echo "${OUTPUTS[$i]}"
    fi
  done

  return 0
}

# Prints summary message corresponding to command result.
_get_summary_message() {
  local RESULT=$1

  case "$RESULT" in
  "$COMMAND_PASSED") _print_passed ;;
  "$COMMAND_FAILED") _print_failed ;;
  "$COMMAND_SKIPPED") _print_skipped ;;
  esac

  return 0
}

# This function prints a summary over all executed commands.
_print_summary() {
  echo # Empty line for better readability.
  _print_info "Results:"

  for i in "${!RESULTS[@]}"; do
    echo -e $(_print_command "$WHITE" "${COMMANDS[$i]}" "${EXPECTED_STATUS_CODES[$i]}") "$(_get_summary_message "${RESULTS[$i]}")"
  done

  return 0
}

# Public API
#
# Use this function to add a command for later execution.
# Put the command in quotes, otherwise add it like you would run it from the command line. E.g.
# command_runner_add "ls -l"
# The command is expected to return 0 to be counted as PASSED.
command_runner_add() {
  if [ "$#" -ne 1 ]; then
    _fail_contract $FUNCNAME "Please provide exactly one command." "$@"
  fi

  COMMANDS+=("$1")
  EXPECTED_STATUS_CODES+=(0)

  return 0
}

# Short alias for command_runner_add.
cra() {
  command_runner_add "$@"
}

# Use this function the same way as command_runner_add but with an additional expected return value.
# Use it if you expect a command to fail, but want to count it as PASSED nevertheless.
# This is useful to temporarily accept failing commands but still run them
# or to explicitly test for true negatives. E.g.
# command_runner_add_with_expectation "ls invalid_path -l" 2
# The command is expected to return the given value to be counted as PASSED.
command_runner_add_with_expectation() {
  if [ "$#" -ne 2 ]; then
    _fail_contract $FUNCNAME "Please provide exactly one command and one expectation." "$@"
  fi

  COMMANDS+=("$1")
  EXPECTED_STATUS_CODES+=("$2")

  return 0
}

# Use this function to run the previously added commands.
# Commands will be executed in the order they were added.
# The exact logging behavior depends on the output settings.
# To run the commands with the default output setting (only the output of failed commands will be printed) use:
# command_runner_run
#
# To run the commands with the verbose output setting (all outputs will be printed) use:
# command_runner_run -v
#
# To run the commands with the streamed output setting (all outputs will be printed during execution) use:
# command_runner_run -s
#
# In all cases all failed commands and a summary will be printed.
# The return value will be 0 if all commands passed and 1 if at least one command failed.
command_runner_run() {
  # Resetting states enables calling command_runner_run multiple times if needed.
  _reset_states

  _set_output_options $FUNCNAME "$@"

  _run_commands
  local RESULTING_STATUS_CODE=$?

  _print_errors
  _print_summary

  return $RESULTING_STATUS_CODE
}

# Short alias for command_runner_run.
crr() {
  command_runner_run "$@"
}

# Use this function to skip remaining commands after first failure.
# This is useful if commands depend on each other like in installation scripts
# or if you want to save runtime in the failure case.
command_runner_stop_on_failure() {
  if [ "$#" -ne 0 ]; then
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  SHOULD_STOP_ON_FAILURE=1

  return 0
}

# Use this function to disable colored output.
command_runner_disable_colored_output() {
  if [ "$#" -ne 0 ]; then
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  COLORED_OUTPUT=0

  return 0
}

# Use this function to enable verbose output.
# Verbose output means that the logs of all commands will be printed
# AFTER execution. Otherwise only the logs of failed commands will be printed.
# The output can either be verbose OR streamed, not both.
command_runner_set_verbose_output() {
  if [ "$#" -ne 0 ]; then
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  CURRENT_OUTPUT=$VERBOSE_OUTPUT

  return 0
}

# Use this function to enable streamed output.
# Streamed output means that the logs of all commands will be printed
# DURING execution. This is helpful if you want to observe the output
# of long running commands.
# The output can either be verbose OR streamed, not both.
command_runner_set_streamed_output() {
  if [ "$#" -ne 0 ]; then
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  CURRENT_OUTPUT=$STREAMED_OUTPUT

  return 0
}
