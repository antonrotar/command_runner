### Tests
The `command_runner` was developed in a test-driven approach. 
If you want to contribute or change anything for your local needs, please run all tests as described below.
If you change a feature or add a new one, please adapt the tests accordingly.

Each test is a standalone executable script which returns 0 if it passes and 1 if it fails.

Each test script contains the most relevant part in its name and ends with `_test.sh`.

[./run_all_tests.sh](./run_all_tests.sh) is a script which will run all `_test.sh` scripts and print all failed tests.

To execute all tests run:
```
./run_all_tests.sh
```
To execute only tests in a particular directory run for instance:
```
./run_all_tests.sh ./command_runner/contract/
```
To execute only one particular test run for instance:
```
./run_all_tests.sh ./command_runner/contract/add_fails_given_no_command_test.sh
```
