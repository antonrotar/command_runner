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

#!/bin/bash

command_runner_reset() {
  commands=()
  results=()
  outputs=()
  expected_results=()
  colored_output=1
  verbose=0
  streamed=0
  commands_valid=1
  return 0
}

command_runner_set_colored_output() {
  colored_output="$1"
  return 0
}

command_runner_set_verbose() {
  verbose="$1"
  return 0
}

command_runner_set_streamed() {
  streamed="$1"
  return 0
}

command_runner_add() {
  if [ ! "$#" -eq 1 ]; then
    _print_colored "1;31m" "FAILED: command_runner_add $@"
    commands_valid=0
    return 1
  fi
  commands+=("$1")
  expected_results+=(0)
  return 0
}

command_runner_add_with_expectation() {
  if [ ! "$#" -eq 2 ]; then
    _print_colored "1;31m" "FAILED: command_runner_add_with_expectation $@"
    commands_valid=0
    return 1
  fi
  commands+=("$1")
  expected_results+=("$2")
  return 0
}

_print_colored() {
  local color="$1"
  shift
  if [ "$colored_output" -eq 1 ]; then
    echo -e "\e[$color$@\e[0m"
  else
    echo "$@"
  fi
  return 0
}

_print_command() {
  _print_colored "0;36m" "$1"
  return 0
}

_print_info() {
  _print_colored "1;96m" "$1"
  return 0
}

_print_passed() {
  _print_colored "0;32m" "PASSED"
  return 0
}

_print_failed() {
  _print_colored "1;31m" "FAILED"
  return 0
}

_run_command_and_store_result() {
  _print_command "$1"
  if [ "$streamed" -eq 1 ]; then
    eval "$1"
  else
    output="$(eval "$1" "2>&1")"
  fi

  results+=("$?")
  outputs+=("$output")
  if [ "$verbose" -eq 1 ]; then
    echo "$output"
  fi
  return 0
}

command_runner_check_commands() {
  if [ "$commands_valid" -eq 1 ]; then
    return 0
  fi
  return 1
}

command_runner_run_commands() {
  for i in "${!commands[@]}"; do
    _run_command_and_store_result "${commands[$i]}"
  done
  return 0
}

command_runner_validate() {
  for i in "${!results[@]}"; do
    if [ ! "${results[$i]}" -eq "${expected_results[$i]}" ]; then
      return 1
    fi
  done
  return 0
}

command_runner_print_errors() {
  _print_info "Errors:"
  for i in "${!results[@]}"; do
    if [ ! "${results[$i]}" -eq "${expected_results[$i]}" ]; then
      echo >&2 "$(_print_info "Error executing:")" "${commands[$i]}"
      echo >&2 "$(_print_info "Output:")"
      echo >&2 "${outputs[$i]}"
      echo >&2
    fi
  done
  return 0
}

command_runner_print_summary() {
  echo
  _print_info "Overall Results:"
  for i in "${!results[@]}"; do
    if [ "${results[$i]}" -eq "${expected_results[$i]}" ]; then
      echo -e "${commands[$i]}" "$(_print_passed)"
    else
      echo -e "${commands[$i]}" "$(_print_failed)"
    fi
  done
  return 0
}

command_runner_run() {
  command_runner_check_commands && command_runner_run_commands && command_runner_print_errors && command_runner_print_summary && command_runner_validate
}

command_runner_reset
