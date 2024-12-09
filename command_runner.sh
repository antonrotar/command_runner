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

_fail_contract() {
  local FUNCTION_NAME="$1"
  local ERROR_LOG="$2"
  shift
  shift

  echo -e "$(_print_failed)" "$FUNCTION_NAME $@"
  echo $ERROR_LOG

  exit 1
}

command_runner_reset() {
  if [ "$#" -gt 0 ]; then
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  COMMANDS=()
  RESULTS=()
  OUTPUTS=()
  EXPECTED_RESULTS=()
  COLORED_OUTPUT=1
  VERBOSE=0
  STREAMED=0
  COMMANDS_VALID=1
  return 0
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
    VERBOSE=1
  elif [ "$#" -eq 1 ]; then
    VERBOSE="$1"
  else
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  return 0
}

command_runner_set_streamed() {
  if [ "$#" -eq 0 ]; then
    STREAMED=1
  elif [ "$#" -eq 1 ]; then
    STREAMED="$1"
  else
    _fail_contract $FUNCNAME "Unexpected arguments." "$@"
  fi

  return 0
}

command_runner_add() {
  if [ "$#" -eq 0 ]; then
    COMMANDS_VALID=0
    _fail_contract $FUNCNAME "Please provide a command." "$@"
  fi

  if [ ! "$#" -eq 1 ]; then
    COMMANDS_VALID=0
    _fail_contract $FUNCNAME "Method does not accept additional arguments. If you want to provide an expectation, please use command_runner_add_with_expectation." "$@"
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

_run_command_and_store_result() {
  _print_command "$@"
  local OUTPUT=""
  if [ "$STREAMED" -eq 1 ]; then
    eval "$1"
  else
    OUTPUT="$(eval "$1" "2>&1")"
  fi

  RESULTS+=("$?")
  OUTPUTS+=("$OUTPUT")
  if [ "$VERBOSE" -eq 1 ]; then
    echo "$OUTPUT"
  fi
  return 0
}

command_runner_check_commands() {
  if [ "$COMMANDS_VALID" -eq 1 ]; then
    return 0
  fi
  return 1
}

command_runner_run_commands() {
  _print_info "Logs:"
  for i in "${!COMMANDS[@]}"; do
    _run_command_and_store_result "${COMMANDS[$i]}" "${EXPECTED_RESULTS[$i]}"
  done
  return 0
}

command_runner_validate() {
  for i in "${!RESULTS[@]}"; do
    if [ ! "${RESULTS[$i]}" -eq "${EXPECTED_RESULTS[$i]}" ]; then
      return 1
    fi
  done
  return 0
}

command_runner_print_errors() {
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

command_runner_print_summary() {
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

command_runner_run() {

  if [ "$#" -eq 1 ]; then
    if [[ "$1" == '-v' ]]; then
      command_runner_set_verbose 1
      shift
    elif [[ "$1" == '-s' ]]; then
      command_runner_set_streamed 1
      shift
    else
      _fail_contract $FUNCNAME "Unexpected argument. Please use -v or -s." "$@"
    fi
  elif [ "$#" -gt 1 ]; then
    _fail_contract $FUNCNAME "Unexpected arguments. Please use -v or -s." "$@"
  fi

  command_runner_check_commands &&
    command_runner_run_commands &&
    command_runner_print_errors &&
    command_runner_print_summary &&
    command_runner_validate
}

command_runner_reset
