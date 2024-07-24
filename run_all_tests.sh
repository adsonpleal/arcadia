#!/bin/sh

# TODO: delete this file in favor of flutter test when macros start supporting tests

TEST_FILES=$(find test -type f -name \*"$_test".dart)

set -e
for test in $TEST_FILES; do
  # if we find the dart package, run as a dart test.
  if grep -cq "package:test/test.dart" $test
  then
    dart run --enable-experiment=macros $test
  else
    flutter test $test
  fi
done
