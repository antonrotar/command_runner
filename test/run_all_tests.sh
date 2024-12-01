#! /bin/bash -u

# This script executes all *_test.sh files in the given directory (and all subdirectories).
# All tests are printed sorted by passed/failed.
# It returns 1 if any test fails.

# Find all tests in given directory.
# If no directory is given, take the script directory.
if [ "$#" -eq 1 ]; then
  TEST_DIRECTORY=$1
else
  TEST_DIRECTORY=$(dirname "$0")
fi
ALL_TESTS=$(find $TEST_DIRECTORY -name *_test.sh)

# Execute all tests.
PASSED_TESTS=()
FAILED_TESTS=()
RETURN_VALUE=0
for TEST in $ALL_TESTS; do
  $TEST
  if [ $? -eq 0 ]; then
    PASSED_TESTS+=($TEST)
  else
    FAILED_TESTS+=($TEST)
    RETURN_VALUE=1
  fi
done

# Print results.
echo "================="
echo "$(echo $ALL_TESTS | wc -w) tests executed."

for TEST in "${PASSED_TESTS[@]}"; do
  echo "$TEST PASSED"
done

for TEST in "${FAILED_TESTS[@]}"; do
  echo "$TEST FAILED"
done

exit $RETURN_VALUE
