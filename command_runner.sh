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

# Implementation.
#
# Variables and states.
COMMANDS=()         # Commands to be executed collected via the "add" functions.
RESULTS=()          # Return codes of the commands after execution.
OUTPUTS=()          # Output logs of the commands after execution.
EXPECTED_RESULTS=() # Optional expected return codes. 0 is set as default expectation.

# Output options
COLORED_OUTPUT=1  # Use colors in command runner output.
REGULAR_OUTPUT=0  # Print failed command outputs only.
VERBOSE_OUTPUT=1  # Print all command outputs AFTER execution.
STREAMED_OUTPUT=2 # Print all command outputs DURING execution.
CURRENT_OUTPUT=$REGULAR_OUTPUT

# Color codes
WHITE="0;0"
NORMAL_RED="0;31"
BOLD_RED="1;31"
NORMAL_GREEN="0;32"
NORMAL_CYAN="0;36"
BOLD_LIGHT_CYAN="1;96"

# Private functions.
#
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

_command_runner_set_verbose() {
  CURRENT_OUTPUT=$VERBOSE_OUTPUT
  return 0
}

_command_runner_set_streamed() {
  CURRENT_OUTPUT=$STREAMED_OUTPUT
  return 0
}

# Helper function for command_runner_run argument handling.
# Verifies that either no option or one of [-v, -s] is set.
_set_output_options() {
  CALLING_FUNCTION="$1"
  shift

  if [ "$#" -eq 1 ]; then
    if [[ "$1" == '-v' ]]; then
      command_runner_set_verbose
    elif [[ "$1" == '-s' ]]; then
      command_runner_set_streamed
    else
      _fail_contract $CALLING_FUNCTION "Unexpected argument. Please use -v or -s." "$@"
    fi
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

_print_failed_command() {
  _print_command "$NORMAL_RED" "$@"

  return 0
}

_print_info() {
  _print_colored "$BOLD_LIGHT_CYAN" "$1"

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

# This is the main function of the whole script.
# Commands are printed and executed here.
# The output is printed given the different output options.
# The result is stored for later evaluation.
_run_command_and_store_result() {
  _print_command "$NORMAL_CYAN" "$@"
  local OUTPUT=""

  if [ "$CURRENT_OUTPUT" -eq "$STREAMED_OUTPUT" ]; then
    # This allows synchronous printing. This is helpful if you want to observe the progress of long running commands.
    # Ideally the output would still be stored in addition to printing it directly.
    # I didn't find a way to accomplish that unfortunately.
    eval "$1"
  else
    OUTPUT="$(eval "$1" "2>&1")"
  fi

  # This line must come directly after the "eval" call. Else "$?" might already be overwritten.
  RESULTS+=("$?")
  OUTPUTS+=("$OUTPUT")

  if [ "$CURRENT_OUTPUT" -eq "$VERBOSE_OUTPUT" ]; then
    echo "$OUTPUT"
  fi

  return 0
}

# Run all stored commands, print them and store the results.
_command_runner_run_commands() {
  _print_info "Running commands:"

  for i in "${!COMMANDS[@]}"; do
    _run_command_and_store_result "${COMMANDS[$i]}" "${EXPECTED_RESULTS[$i]}"
  done

  return 0
}

# The three functions below have similar code but are kept separate on purpose.
# They represent different semantical concepts and might change at different times for different reasons.
#
# This function evaluates if all commands have the expected results.
_command_runner_evaluate() {
  for i in "${!RESULTS[@]}"; do
    if [ ! "${RESULTS[$i]}" -eq "${EXPECTED_RESULTS[$i]}" ]; then
      return 1
    fi
  done

  return 0
}

# This function prints the output of all failed commands.
_command_runner_print_errors() {
  echo
  _print_info "Errors:"

  for i in "${!RESULTS[@]}"; do
    if [ ! "${RESULTS[$i]}" -eq "${EXPECTED_RESULTS[$i]}" ]; then
      _print_failed_command "${COMMANDS[$i]}" "${EXPECTED_RESULTS[$i]}"
      echo "${OUTPUTS[$i]}"
    fi
  done

  return 0
}

# This function prints a summary over all executed commands.
_command_runner_print_summary() {
  echo
  _print_info "Results:"

  for i in "${!RESULTS[@]}"; do
    if [ "${RESULTS[$i]}" -eq "${EXPECTED_RESULTS[$i]}" ]; then
      echo -e $(_print_command "$WHITE" "${COMMANDS[$i]}" "${EXPECTED_RESULTS[$i]}") "$(_print_passed)"
    else
      echo -e $(_print_command "$WHITE" "${COMMANDS[$i]}" "${EXPECTED_RESULTS[$i]}") "$(_print_failed)"
    fi
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
  if [ ! "$#" -eq 1 ]; then
    _fail_contract $FUNCNAME "Please provide exactly one command." "$@"
  fi

  COMMANDS+=("$1")
  EXPECTED_RESULTS+=(0)

  return 0
}

# Use this function the same way as command_runner_add but with an additional expected return value.
# Use it if you expect a command to fail, but want to count it as PASSED nevertheless.
# This is useful to temporarily accept failing commands but still run them
# or to explicitly test for true negatives. E.g.
# command_runner_add_with_expectation "ls invalid_path -l" 2
# The command is expected to return the given value to be counted as PASSED.
command_runner_add_with_expectation() {
  if [ ! "$#" -eq 2 ]; then
    _fail_contract $FUNCNAME "Please provide exactly one command and one expectation." "$@"
  fi

  COMMANDS+=("$1")
  EXPECTED_RESULTS+=("$2")

  return 0
}

# Use this function to run the previously added commands.
# Commands will be executed in the order they were added.
# The exact logging behavior depends on the output settings:
# command_runner_run
# will run all commands with default output settings.
# command_runner_run -v
# will run all commands with verbose output settings.
# command_runner_run -s
# will run all commands with streamed output settings.
# In all cases all failed commands and a summary will be printed.
# The return value will be 0 if all commands passed and 1 if at least one command failed.
command_runner_run() {
  _set_output_options $FUNCNAME "$@"

  _command_runner_run_commands &&
    _command_runner_print_errors &&
    _command_runner_print_summary &&
    _command_runner_evaluate

  RETURN_VALUE=$?

  # Reset results and outputs.
  # This enables calling command_runner_run multiple times if needed.
  RESULTS=()
  OUTPUTS=()

  return $RETURN_VALUE
}

# Use this function to disable colored output.
command_runner_disable_colored_output() {
  if [ "$#" -ne 0 ]; then
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  COLORED_OUTPUT=0

  return 0
}

# Use this function to specify if verbose output should be used.
# Verbose output means that the logs of all commands will be printed
# AFTER execution. Otherwise only the logs of failed commands will be printed.
# command_runner_set_verbose
# is equivalent to
# command_runner_set_verbose 1
# and will enable verbose output.
# command_runner_set_verbose 0
# will disable it.
command_runner_set_verbose() {
  if [ "$#" -ne 0 ]; then
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  _command_runner_set_verbose

  return 0
}

# Use this function to specify if streamed output should be used.
# Streamed output means that the logs of all commands will be printed
# DURING execution. This is helpful if you want to observe the output
# of long running commands.
# command_runner_set_streamed
# is equivalent to
# command_runner_set_streamed 1
# and will enable streamed output.
# command_runner_set_streamed 0
# will disable it.
command_runner_set_streamed() {
  if [ "$#" -ne 0 ]; then
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  _command_runner_set_streamed

  return 0
}
