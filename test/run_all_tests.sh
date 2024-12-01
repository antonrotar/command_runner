#! /bin/bash -u

# This script executes all *_test.sh files in the given directory (and all subdirectories).
# All failed tests are printed.
# It returns 1 if any test fails.

# Find all tests in given directory.
# If no directory is given, take the script directory.
if [ "$#" -eq 1 ]; then
  TEST_DIRECTORY=$1
else
  TEST_DIRECTORY=$(dirname "$0")
fi
ALL_TESTS=$(find $TEST_DIRECTORY -name *_test.sh)

# Execute all tests. Store failed tests in array.
FAILED_TESTS=()
for TEST in $ALL_TESTS; do
  $TEST
  if [ $? -ne 0 ]; then
    FAILED_TESTS+=($TEST)
  fi
done

# Compute statistics.
NUMBER_OF_TESTS=$(echo $ALL_TESTS | wc -w)
NUMBER_OF_FAILED_TESTS=${#FAILED_TESTS[@]}
NUMBER_OF_SUCCESSFUL_TESTS=$((NUMBER_OF_TESTS - NUMBER_OF_FAILED_TESTS))
echo "$NUMBER_OF_SUCCESSFUL_TESTS/$NUMBER_OF_TESTS tests passed."

# If any tests failed, print them and exit with error.
if [ "$NUMBER_OF_FAILED_TESTS" -ne 0 ]; then
  echo "Failed tests:"
  for FAILED_TEST in "${FAILED_TESTS[@]}"; do
    echo $FAILED_TEST
  done
  exit 1
fi

exit 0
