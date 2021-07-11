#!/bin/sh
# shellcheck shell=dash

# Load code to be tested
. ../lib

oneTimeSetUp() {
    printf "[INFO] Current shell is: %s\n" "$(cat /proc/$$/cmdline | tr '\0' '\n' | head -n1)"
    printf "[INFO] Utility paths:\n"
    for util in awk sed grep; do
        printf "%8s: %s\n" "$util" "$(which "$util")"
    done
}

setUp() {
    TEST_TMPDIR="$(mktemp -d)"
    touch "$TEST_TMPDIR/.apply_test_dir"
}

tearDown() {
    if test -f "$TEST_TMPDIR/.apply_test_dir"; then
        rm -rf "$TEST_TMPDIR"
    fi
}

testSubstitute_Basic() {
    echo "hello world" > "$TEST_TMPDIR/input.txt"
    substitute \
        "$TEST_TMPDIR/input.txt" \
        "$TEST_TMPDIR/output.txt" \
        "hello" "goodbye"

    assertEquals "goodbye world" "$(cat "$TEST_TMPDIR/output.txt")"
}

testSubstitute_Multi() {
    echo "hello hello hello" > "$TEST_TMPDIR/input.txt"
    substitute \
        "$TEST_TMPDIR/input.txt" \
        "$TEST_TMPDIR/output.txt" \
        "hello" "hi"

    assertEquals "hi hi hi" "$(cat "$TEST_TMPDIR/output.txt")"
}

testSubstitute_Multiline() {
    printf "hello\nworld\nhello\nworld\n" > "$TEST_TMPDIR/input.txt"

    substitute \
        "$TEST_TMPDIR/input.txt" \
        "$TEST_TMPDIR/output.txt" \
        "hello\nworld" "$(printf "greetings\nall")"

    assertEquals \
        "$(printf "greetings\nall\ngreetings\nall")" \
        "$(cat "$TEST_TMPDIR/output.txt")"
}

testSubstituteInPlace() {
    echo "hello hello hello" > "$TEST_TMPDIR/sub.txt"
    substituteInPlace \
        "$TEST_TMPDIR/sub.txt" \
        "hello" "hi"

    assertEquals "hi hi hi" "$(cat "$TEST_TMPDIR/sub.txt")"
}

# Load shUnit2
. ./shunit2
