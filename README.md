## Command Runner
[![CI Status](https://github.com/antonrotar/command_runner/actions/workflows/ci.yml/badge.svg)](https://github.com/antonrotar/command_runner/actions/workflows/ci.yml)

This is a small bash library called `command_runner`.
- It can run a list of commands in a script and report the results.
- It provides a simple API and some output options.
- It is thoroughly tested.

Next steps:
- Example use cases are [Use as a local CI](#use-as-a-local-ci) and [Use as an installation script](#use-as-an-installation-script)
- Executable examples can be found under [examples](./examples/)
- Tests can be found under [test](./test/)
- [API Reference](#api-reference)

### Use as a local CI
In most projects you will want to run some commands repeatedly. Like run linters, build, deploy, test your software, etc.
The `command_runner` provides you with a simple API to collect these commands in a single script and have a nice report after execution.

An example could look like:
```bash
# my_project_ci.sh

# Import command runner script.
source "$COMMAND_RUNNER_DIRECTORY/command_runner.sh"

# Add commands like you would run them in the command line.
command_runner_add "./scripts/check_clang_format.sh"
command_runner_add "bazel build //..."
command_runner_add "bazel test //..."
command_runner_add "bazel test --config=sanitizer //..."

# Run commands.
# Passing "$@" is not required, but helpful to run the whole script with [-v, -s].
command_runner_run "$@"
```
If all commands pass, a short summary will be printed and the return value will be 0:
```
Running commands:
./scripts/check_clang_format.sh
bazel build //...
bazel test //...
bazel test --config=sanitizer //...

Errors:

Results:
./scripts/check_clang_format.sh PASSED
bazel build //... PASSED
bazel test //... PASSED
bazel test --config=sanitizer //... PASSED
```
If any command fails, the output of this command will be printed in the `Errors` section and the return value will be 1:
```
Running commands:
./scripts/check_clang_format.sh
bazel build //...
bazel test //...
bazel test --config=sanitizer //...

Errors:
./scripts/check_clang_format.sh
File main.cpp does not comply with the given clang-format rules.

Results:
./scripts/check_clang_format.sh FAILED
bazel build //... PASSED
bazel test //... PASSED
bazel test --config=sanitizer //... PASSED
```
The actual output will be better readable using different colors. Unfortunately it is impossible to demonstrate that in a github README.

The verbosity can be configured, please check the [API Reference](#api-reference).

### Use as an installation script
The `command_runner` was developed for the CI use case. However, it can also be used to automate installation routines.

An example could look like:
```bash
# install_ubuntu_mono_nerd_font.sh

# Import command runner script.
source "$COMMAND_RUNNER_DIRECTORY/command_runner.sh"

FONTS_DIRECTORY="$HOME/.local/share/fonts"
FONT_VERSION="v3.3.0"
FONT_ARCHIVE="UbuntuMono.zip"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/$FONT_VERSION/$FONT_ARCHIVE"

# Tell command runner to stop on failure.
# This will skip all subsequent commands should any command fail.
command_runner_stop_on_failure

# Add commands like you would run them in the command line.
command_runner_add "mkdir -p $FONTS_DIRECTORY"
command_runner_add "wget $FONT_URL"
command_runner_add "unzip -o $FONT_ARCHIVE -d $FONTS_DIRECTORY"
command_runner_add "rm $FONT_ARCHIVE"
command_runner_add "fc-cache -fv"

# Run commands.
# Passing "$@" is not required, but helpful to run the whole script with [-v, -s].
command_runner_run "$@"
```
If all commands pass, a short summary will be printed and the return value will be 0:
```
Running commands:
mkdir -p /home/anton/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/UbuntuMono.zip
unzip -o UbuntuMono.zip -d /home/anton/.local/share/fonts
rm UbuntuMono.zip
fc-cache -fv

Errors:

Results:
mkdir -p /home/anton/.local/share/fonts PASSED
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/UbuntuMono.zip PASSED
unzip -o UbuntuMono.zip -d /home/anton/.local/share/fonts PASSED
rm UbuntuMono.zip PASSED
fc-cache -fv PASSED
```
If any command fails, the output of this command will be printed in the `Errors` section and the return value will be 1.
In addition to that, since `command_runner_stop_on_failure` was set, all subsequent commands will be skipped:
```
Running commands:
mkdir -p /home/anton/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/UbuntuMono.zip
COMMAND FAILED AND STOP ON FAILURE IS ENABLED. SKIPPING REMAINING COMMANDS.
unzip -o UbuntuMono.zip -d /home/anton/.local/share/fonts
rm UbuntuMono.zip
fc-cache -fv

Errors:
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/UbuntuMono.zip
--2025-01-04 23:59:25--  https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/UbuntuMono.zip
Resolving github.com (github.com)... 140.82.121.3
Connecting to github.com (github.com)|140.82.121.3|:443... connected.
HTTP request sent, awaiting response... 404 Not Found
2025-01-04 23:59:25 ERROR 404: Not Found.

Results:
mkdir -p /home/anton/.local/share/fonts PASSED
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/UbuntuMono.zip FAILED
unzip -o UbuntuMono.zip -d /home/anton/.local/share/fonts SKIPPED
rm UbuntuMono.zip SKIPPED
fc-cache -fv SKIPPED
```
The actual output will be better readable using different colors. Unfortunately it is impossible to demonstrate that in a github README.

The verbosity can be configured, please check the [API Reference](#api-reference).

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
