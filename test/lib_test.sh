#!/bin/sh
# shellcheck shell=dash

# Load code to be tested
. ../lib

oneTimeSetUp() {
    if [ -n "${VERBOSE:-}" ]; then
        printf "[INFO] Current shell is: %s\n" "$(</proc/$$/cmdline tr '\0' '\n' | head -n1)"
        printf "[INFO] Utility paths:\n"
        for util in awk sed grep; do
            printf "%8s: %s\n" "$util" "$(which "$util")"
        done
    fi
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

testQuote() {
    local input expected

    { input="$(cat)"; } <<EOF
foo'bar"baz'
EOF

    { expected="$(cat)"; } <<EOF
'foo'\\''bar"baz'\\'''
EOF

    assertEquals "$expected" "$(quote "$input")"
}

testFnmatch() {
    assertTrue 'fnmatch "f??*" "foobar"'
    assertFalse 'fnmatch "f??*" "fo"'
    assertFalse 'fnmatch "f??*" "loob"'
}

testEpochseconds() {
    # TODO(andrew-d): better test

    # Assert that it's numeric by deleting all numbers and verifying that
    # there's nothing left.
    assertEquals "" "$(epochseconds | tr -d '[0-9]')"
}

testUserHomedir() {
    # TODO(andrew-d): this doesn't work in the Nix sandbox; detect this and
    # skip the test for now.
    if [ "$HOME" = "/homeless-shelter" ]; then
        return
    fi

    assertEquals "$HOME" "$(user_homedir "$USER")"
}

testSponge() {
    for i in $(seq 1 10000); do
        echo "i am a test line of length 30" >> "$TEST_TMPDIR/largefile.txt"
        echo "i am a neat line of length 30" >> "$TEST_TMPDIR/expected.txt"
    done

    # Modify the file; if we don't sponge, this will probably overwrite things
    # and won't work.
    cat "$TEST_TMPDIR/largefile.txt" | \
        sed 's/test/neat/g' | \
        sponge "$TEST_TMPDIR/largefile.txt"

    # The files should be equal (currently, we just compare CRCs)
    assertEquals "$(cksum < "$TEST_TMPDIR/largefile.txt")" "$(cksum < "$TEST_TMPDIR/expected.txt")"
}

testSponge_Permissions() {
    echo "i am the input file" > "$TEST_TMPDIR/input.txt"
    echo "i am the output file" > "$TEST_TMPDIR/output.txt"

    # Set a strange permission on the output file that we will replicate.
    chmod 0741 "$TEST_TMPDIR/output.txt"

    cat "$TEST_TMPDIR/input.txt" | sponge "$TEST_TMPDIR/output.txt"

    # The files should be equal
    assertEquals "$(cat "$TEST_TMPDIR/input.txt")" "$(cat "$TEST_TMPDIR/output.txt")"
    assertEquals "741" "$(stat -c '%a' "$TEST_TMPDIR/output.txt")"
}

testSponge_Append() {
    echo "one" > "$TEST_TMPDIR/input.txt"
    echo "two" > "$TEST_TMPDIR/output.txt"

    cat "$TEST_TMPDIR/input.txt" | sponge -a "$TEST_TMPDIR/output.txt"

    assertEquals "$(printf 'two\none\n')" "$(cat "$TEST_TMPDIR/output.txt")"
}

# Load shUnit2
. ./shunit2
