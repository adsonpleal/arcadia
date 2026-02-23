#!/bin/sh

TEST_FILES=$(find test -type f -name \*"$_test".dart)

set -e
for test in $TEST_FILES; do
  flutter test $test
done
