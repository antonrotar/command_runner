#!/bin/bash

script_directory="$(dirname "$0")"
if ! source "$script_directory/../command_runner.sh"; then
  exit 1
fi

command_runner_add "echo Inner pass;exit 0"
command_runner_add "echo Inner fail;exit 42"

command_runner_run
