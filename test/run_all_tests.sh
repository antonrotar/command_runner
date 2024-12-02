#! /bin/bash -u

# This script executes all *_test.sh files in the given directory (and all subdirectories).
# All tests are printed sorted by passed/failed.
# It returns 1 if any test fails.

# Variables and constants.
PASSED_MESSAGE="\e[0;32mPASSED\e[0m"
FAILED_MESSAGE="\e[1;31mFAILED\e[0m"
PASSED_TESTS=()
FAILED_TESTS=()
RETURN_VALUE=0

# Find all tests in given directory.
# If no directory is given, take the script directory.
if [ "$#" -eq 1 ]; then
  TEST_DIRECTORY=$1
else
  TEST_DIRECTORY=$(dirname "$0")
fi
ALL_TESTS=$(find $TEST_DIRECTORY -name *_test.sh)

# Execute all tests.
for TEST in $ALL_TESTS; do
  echo "Executing $TEST"
  $TEST
  if [ $? -eq 0 ]; then
    PASSED_TESTS+=($TEST)
    echo -e $PASSED_MESSAGE
  else
    FAILED_TESTS+=($TEST)
    RETURN_VALUE=1
    echo -e $FAILED_MESSAGE
  fi
done

# Print results.
echo "================="
echo "$(echo $ALL_TESTS | wc -w) tests executed."

for TEST in "${PASSED_TESTS[@]}"; do
  echo -e "$TEST $PASSED_MESSAGE"
done

for TEST in "${FAILED_TESTS[@]}"; do
  echo -e "$TEST $FAILED_MESSAGE"
done

exit $RETURN_VALUE
