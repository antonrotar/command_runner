## Command Runner
[![CI Status](https://github.com/antonrotar/command_runner/actions/workflows/ci.yml/badge.svg)](https://github.com/antonrotar/command_runner/actions/workflows/ci.yml)

This is a small bash library called `command_runner`.
It can run a list of commands in a script and report the results.
In comparison to using a plain bash script you have a better control over execution and printing.
Per default only the outputs of the failed commands will be printed, the rest will only be summarized.
You can decide if you want to run all commands even if some failed or if you want to stop after first failure.
The report will in any case contain all configured commands with their respective execution status.
The overall status code will be propagated consistently which enables the usage of the `command_runner` in the scope of a larger tooling setup.

Next steps:
- Example use case is [Use as a simple CI](#use-as-a-simple-ci)
- Executable examples can be found under [examples](./examples/)
- Tests can be found under [test](./test/)
- [API Reference](#api-reference)

### Use as a simple CI
In most projects you will want to run some commands repeatedly. Like run linters, build, deploy, test your software, etc.
The `command_runner` provides you with a simple API to collect these commands in a single script and have a nice report after execution.

An example could look like:
```bash
# my_project_ci.sh

# Import command runner script.
SCRIPT_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIRECTORY/../command_runner/command_runner.sh"

# Add the following line if you want to stop on first failure
# and skip all remaining commands:
# command_runner_stop_on_failure

# Add commands like you would run them in the command line.
cra "$SCRIPT_DIRECTORY/check_clang_format.sh"
cra "bazel build //..."
cra "bazel test //..."
cra "bazel test --config=sanitizer //..."

# Run commands.
# Passing "$@" is not required, but helpful to run the whole script with [-v, -s].
crr "$@"
```
If all commands pass, a short summary will be printed and the return value will be 0:

![All commands pass](./docs/all_passing.png?raw=true)

If any command fails, the output of this command will be printed in the `Errors` section and the return value will be 1:

![Commands fail and continue](./docs/failing_and_continue.png?raw=true)

Per default all commands are executed. If you want to stop on first failure and skip the remaining commands,
please add `command_runner_stop_on_failure` to your script. The output will then be:

![Commands fail and stop](./docs/failing_and_stop.png?raw=true)

Per default only the logs of failed commands will be printed, but the verbosity can be configured.
Please check the [API Reference](#api-reference).

### API Reference

#### command_runner_add
Use this function to add a command for later execution.
Put the command in quotes, otherwise add it like you would run it from the command line. E.g.
```bash
command_runner_add "ls -l"
```
The command is expected to return 0 to be counted as PASSED.

#### cra
Short alias for `command_runner_add`. Improves brevity and focus on the commands at hand.

#### command_runner_add_with_expectation
Use this function the same way as `command_runner_add` but with an additional expected return value.
Use it if you expect a command to fail, but want to count it as PASSED nevertheless.
This is useful to temporarily accept failing commands but still run them
or to explicitly test for true negatives. E.g.
```bash
command_runner_add_with_expectation "ls invalid_path -l" 2
```
The command is expected to return the given value to be counted as PASSED.

#### command_runner_run
Use this function to run the previously added commands.
Commands will be executed in the order they were added.
The exact logging behavior depends on the output settings.
To run the commands with the default output setting (only the output of failed commands will be printed) use:
```bash
command_runner_run
```
To run the commands with the verbose output setting (all outputs will be printed) use:
```bash
command_runner_run -v
```
To run the commands with the streamed output setting (all outputs will be printed during execution) use:
```bash
command_runner_run -s
```
In all cases all failed commands and a summary will be printed.
The return value will be 0 if all commands passed and 1 if at least one command failed.

#### crr
Short alias for `command_runner_run`. Improves brevity and focus on the commands at hand.

#### command_runner_stop_on_failure
Use this function to skip remaining commands after first failure.
This is useful if commands depend on each other like in installation scripts
or if you want to save runtime in the failure case.

#### command_runner_disable_colored_output
Use this function to disable colored output.

#### command_runner_set_verbose_output
Use this function to enable verbose output.
Verbose output means that the logs of all commands will be printed
AFTER execution. Otherwise only the logs of failed commands will be printed.
The output can either be verbose OR streamed, not both.

#### command_runner_set_streamed_output
Use this function to enable streamed output.
Streamed output means that the logs of all commands will be printed
DURING execution. This is helpful if you want to observe the output
of long running commands.
The output can either be verbose OR streamed, not both.
