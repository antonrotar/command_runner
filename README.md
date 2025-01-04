### Command Runner
This is a small bash library called "command_runner".
It can be used to run a collection of (command line) commands repeatedly and report the results.

#### Use as local a CI
In most projects you will want to run some commands repeatedly. Like run linters, build, deploy, test your software, etc.
The command_runner provides you with a simple API to collect these commands in a single script and have a nice report after execution.
An example could look like:
```bash
# my_project_ci.sh

source "$COMMAND_RUNNER_DIRECTORY/command_runner.sh"

command_runner_add "./scripts/check_clang_format.sh"
command_runner_add "bazel build //..."
command_runner_add "bazel test //..."
command_runner_add "bazel test --config=sanitizer //..."

command_runner_run "$@"
```
Just add the commands like you would run them from the command line.
The command runner will per default run all commands, print the output of failed commands and print a summary.
It will return 0 if all commands passed and 1 if at least one command failed such that it can be used in the scope of a larger tooling setup.

#### Use as an installation script
The command_runner was developed for the CI use case, however it can also be used to automated installation routines.
An example could look like:
```bash
# install_ubuntu_mono_nerd_font.sh

source "$COMMAND_RUNNER_DIRECTORY/command_runner.sh"

FONTS_DIRECTORY="$HOME/.local/share/fonts"

FONT_VERSION="v3.3.0"
FONT_ARCHIVE="UbuntuMono.zip"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/$FONT_VERSION/$FONT_ARCHIVE"

command_runner_stop_on_failure

command_runner_add "mkdir -p $FONTS_DIRECTORY"
command_runner_add "wget $FONT_URL"
command_runner_add "unzip -o $FONT_ARCHIVE -d $FONTS_DIRECTORY"
command_runner_add "rm $FONT_ARCHIVE"
command_runner_add "fc-cache -fv"

command_runner_run "$@"
```
Using `command_runner_stop_on_failure` will skip all remaining commands after first failure, which is important in this case.
You could of course just run all commands in a regular script without the redirection over the command_runner.
However, you will lose the printing capabilities which provide you a clean log if all goes well and a precise error log if something goes wrong to be able to locate the error quicker.

