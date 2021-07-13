#!/bin/sh
# shellcheck shell=dash

oneTimeSetUp() {
    if [ -n "${VERBOSE:-}" ]; then
        printf "[INFO] Current shell is: %s\n" "$(</proc/$$/cmdline tr '\0' '\n' | head -n1)"
    fi
}

setUp() {
    TEST_TMPDIR="$(mktemp -d)"
    touch "$TEST_TMPDIR/.apply_test_dir"

    # Need these two script files
    cp ../lib ../run "$TEST_TMPDIR"

    mkdir -p "$TEST_TMPDIR/units" "$TEST_TMPDIR/groups"

    # Some basic units
    printf '#!/bin/sh\necho hello world' > "$TEST_TMPDIR/units/one"
    printf '#!/bin/sh\necho second message' > "$TEST_TMPDIR/units/two"
    printf '#!/bin/sh\necho oops\nexit 1' > "$TEST_TMPDIR/units/fail"

    # Make everything executable
    chmod +x "$TEST_TMPDIR"/units/*

    # Some groups that to tie things together
    printf "groups/group2\n" > "$TEST_TMPDIR/groups/group1"
    printf "units/two\n"     > "$TEST_TMPDIR/groups/group2"
    printf "units/fail\n"    > "$TEST_TMPDIR/groups/fail"

    #tree "$TEST_TMPDIR"
}

tearDown() {
    if test -f "$TEST_TMPDIR/.apply_test_dir"; then
        rm -rf "$TEST_TMPDIR"
    fi
}

testRunUnits() {
    (
        cd "$TEST_TMPDIR"
        ./run units/one units/two
    ) >"$TEST_TMPDIR/stdout" 2>"$TEST_TMPDIR/stderr"

    local expected
    { expected="$(cat)"; } <<EOF
^[[33m** ^[[34munits/one^[(B^[[m ^[[32mOK^[(B^[[m
^[[33m** ^[[34munits/two^[(B^[[m ^[[32mOK^[(B^[[m
EOF

    # Use 'cat -v' to display control characters so we can assert on them
    assertEquals "$expected" "$(cat -v "$TEST_TMPDIR/stdout")"
    assertNull "$(cat "$TEST_TMPDIR/stderr")"
}

testUnitFailure() {
    set +e
    (
        cd "$TEST_TMPDIR"
        ./run units/fail
    ) >"$TEST_TMPDIR/stdout" 2>"$TEST_TMPDIR/stderr"
    set -e

    local stdout_expected stderr_expected
    { stdout_expected="$(cat)"; } <<EOF
^[[33m** ^[[34munits/fail^[(B^[[m ^[[31mFAILED^[(B^[[m
EOF

    { stderr_expected="$(cat)"; } <<EOF
Here are the last lines of output:
oops
For details, see TMPDIR/units_fail.log
EOF

    # Use 'cat -v' to display control characters so we can assert on them
    assertEquals "$stdout_expected" "$(cat -v "$TEST_TMPDIR/stdout")"

    # Remove temporary directory from our stderr output before asserting
    local stderr_actual
    stderr_actual="$(cat -v "$TEST_TMPDIR/stderr")"
    stderr_actual="$(printf "%s\n" "$stderr_actual" | sed "s|$TMPDIR/.*/units_fail.log|TMPDIR/units_fail.log|g")"
    assertEquals "$stderr_expected" "$stderr_actual"
}

testRunGroup() {
    (
        cd "$TEST_TMPDIR"
        ./run groups/group1
    ) >"$TEST_TMPDIR/stdout" 2>"$TEST_TMPDIR/stderr"

    local expected
    { expected="$(cat)"; } <<EOF
^[[33m** ^[[34mgroups/group1 ^[[33mprocessing...^[(B^[[m
^[[33m** ^[[34mgroups/group2 ^[[33mprocessing...^[(B^[[m
^[[33m** ^[[34munits/two^[(B^[[m ^[[32mOK^[(B^[[m
^[[33m** ^[[34mgroups/group2 ^[[32mOK^[(B^[[m
^[[33m** ^[[34mgroups/group1 ^[[32mOK^[(B^[[m
EOF

    # Use 'cat -v' to display control characters so we can assert on them
    assertEquals "$expected" "$(cat -v "$TEST_TMPDIR/stdout")"
    assertNull "$(cat "$TEST_TMPDIR/stderr")"
}

testGroupFail() {
    (
        cd "$TEST_TMPDIR"
        ./run groups/fail
    ) >"$TEST_TMPDIR/stdout" 2>"$TEST_TMPDIR/stderr"

    local stdout_expected stderr_expected
    { stdout_expected="$(cat)"; } <<EOF
^[[33m** ^[[34mgroups/fail ^[[33mprocessing...^[(B^[[m
^[[33m** ^[[34munits/fail^[(B^[[m ^[[31mFAILED^[(B^[[m
EOF

    { stderr_expected="$(cat)"; } <<EOF
Here are the last lines of output:
oops
For details, see TMPDIR/units_fail.log
EOF

    # Use 'cat -v' to display control characters so we can assert on them
    assertEquals "$stdout_expected" "$(cat -v "$TEST_TMPDIR/stdout")"

    # Remove temporary directory from our stderr output before asserting
    local stderr_actual
    stderr_actual="$(cat -v "$TEST_TMPDIR/stderr")"
    stderr_actual="$(printf "%s\n" "$stderr_actual" | sed "s|$TMPDIR/.*/units_fail.log|TMPDIR/units_fail.log|g")"
    assertEquals "$stderr_expected" "$stderr_actual"
}

# Load shUnit2
. ./shunit2
