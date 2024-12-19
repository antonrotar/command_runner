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
COLORED_OUTPUT=1    # Use colors in command runner output.
VERBOSE=0           # Print all command outputs AFTER execution.
STREAMED=0          # Print all command outputs DURING execution.
COMMANDS_VALID=1    # Set to "false" on any invalid added command.

# Private functions.
#
# Helper function for contract guard clause. Prints error log and exits the script.
_fail_contract() {
  local FUNCTION_NAME="$1"
  local ERROR_LOG="$2"
  shift
  shift

  echo -e "$(_print_failed)" "$FUNCTION_NAME $@"
  echo $ERROR_LOG

  exit 1
}

# If both verbose and streamed options are set, the behavior might be unexpected.
# This function ensures only one option is set to 1.
_command_runner_set_verbose() {
  VERBOSE="$1"

  if [ "$1" -eq 1 ]; then
    STREAMED=0
  fi

  return 0
}

# If both verbose and streamed options are set, the behavior might be unexpected.
# This function ensures only one option is set to 1.
_command_runner_set_streamed() {
  STREAMED="$1"

  if [ "$1" -eq 1 ]; then
    VERBOSE=0
  fi

  return 0
}

# Helper function for command_runner_run argument handling.
# Verifies that either no option or one of [-v, -s].
_set_output_options() {
  CALLING_FUNCTION="$1"
  shift

  if [ "$#" -eq 1 ]; then
    if [[ "$1" == '-v' ]]; then
      command_runner_set_verbose 1
    elif [[ "$1" == '-s' ]]; then
      command_runner_set_streamed 1
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
  local NORMAL_CYAN="0;36"
  _print_colored "$NORMAL_CYAN" "$@"

  return 0
}

_print_info() {
  local BOLD_LIGHT_CYAN="1;96"
  _print_colored "$BOLD_LIGHT_CYAN" "$1"

  return 0
}

_print_passed() {
  local NORMAL_GREEN="0;32"
  _print_colored "$NORMAL_GREEN" "PASSED"

  return 0
}

_print_failed() {
  local BOLD_RED="1;31"
  _print_colored "$BOLD_RED" "FAILED"

  return 0
}

# This is the main function of the whole script.
# Commands are printed and executed here.
# The output is printed given the different output options.
# The result is stored for later evaluation.
_run_command_and_store_result() {
  _print_command "$@"
  local OUTPUT=""

  if [ "$STREAMED" -eq 1 ]; then
    # This allows synchronous printing. This is helpful if you want to observe the progress of long running commands.
    # Ideally the output would still be stored in addition to printing it directly.
    # I didn't find a way to accomplish that unfortunately.
    eval "$1"
  else
    OUTPUT="$(eval "$1" "2>&1")"
  fi

  # This line must come directly after the "eval" call. Else "$?"" might be already be overwritten.
  RESULTS+=("$?")
  OUTPUTS+=("$OUTPUT")

  if [ "$VERBOSE" -eq 1 ]; then
    echo "$OUTPUT"
  fi

  return 0
}

# Additional safety net, just in case that the exit calls from the contract are ignored somehow.
# Prevents running invalid commands.
_command_runner_check_commands() {
  if [ "$COMMANDS_VALID" -eq 1 ]; then
    return 0
  fi
  return 1
}

# Run all stored commands, print them and store the results.
_command_runner_run_commands() {
  _print_info "Logs:"

  for i in "${!COMMANDS[@]}"; do
    _run_command_and_store_result "${COMMANDS[$i]}" "${EXPECTED_RESULTS[$i]}"
  done

  return 0
}

# The three functions below have similar code but are kept separate on purpose.
# They represent different semantical concepts and might change at different times for different reasons.
#
# This function evaluates if all commands have the expected results.
_command_runner_validate() {
  for i in "${!RESULTS[@]}"; do
    if [ ! "${RESULTS[$i]}" -eq "${EXPECTED_RESULTS[$i]}" ]; then
      return 1
    fi
  done

  return 0
}

# This function prints the output of all failed commands.
_command_runner_print_errors() {
  _print_info "Errors:"

  for i in "${!RESULTS[@]}"; do
    if [ ! "${RESULTS[$i]}" -eq "${EXPECTED_RESULTS[$i]}" ]; then
      echo "$(_print_info "Error executing:")" "${COMMANDS[$i]}" "${EXPECTED_RESULTS[$i]}"
      echo "$(_print_info "Output:")"
      echo "${OUTPUTS[$i]}"
      echo
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
      echo -e "${COMMANDS[$i]}" "${EXPECTED_RESULTS[$i]}" "$(_print_passed)"
    else
      echo -e "${COMMANDS[$i]}" "${EXPECTED_RESULTS[$i]}" "$(_print_failed)"
    fi
  done

  return 0
}

# Public API
command_runner_add() {
  if [ "$#" -eq 0 ]; then
    COMMANDS_VALID=0
    _fail_contract $FUNCNAME "Please provide a command." "$@"
  fi

  if [ ! "$#" -eq 1 ]; then
    COMMANDS_VALID=0
    _fail_contract $FUNCNAME "Function does not accept additional arguments. If you want to provide an expectation, please use command_runner_add_with_expectation." "$@"
  fi

  COMMANDS+=("$1")
  EXPECTED_RESULTS+=(0)

  return 0
}

command_runner_add_with_expectation() {
  if [ "$#" -eq 0 ]; then
    COMMANDS_VALID=0
    _fail_contract $FUNCNAME "Please provide a command." "$@"
  fi

  if [ ! "$#" -eq 2 ]; then
    COMMANDS_VALID=0
    _fail_contract $FUNCNAME "Please provide exactly one expectation." "$@"
  fi

  COMMANDS+=("$1")
  EXPECTED_RESULTS+=("$2")

  return 0
}

command_runner_run() {
  _set_output_options $FUNCNAME "$@"

  _command_runner_check_commands &&
    _command_runner_run_commands &&
    _command_runner_print_errors &&
    _command_runner_print_summary &&
    _command_runner_validate
}

command_runner_set_colored_output() {
  if [ "$#" -eq 0 ]; then
    COLORED_OUTPUT=1
  elif [ "$#" -eq 1 ]; then
    COLORED_OUTPUT="$1"
  else
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  return 0
}

command_runner_set_verbose() {
  if [ "$#" -eq 0 ]; then
    _command_runner_set_verbose 1
  elif [ "$#" -eq 1 ]; then
    _command_runner_set_verbose "$1"
  else
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  return 0
}

command_runner_set_streamed() {
  if [ "$#" -eq 0 ]; then
    _command_runner_set_streamed 1
  elif [ "$#" -eq 1 ]; then
    _command_runner_set_streamed "$1"
  else
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  return 0
}
