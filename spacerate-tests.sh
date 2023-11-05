#!/usr/bin/env bash
set -u

old_starting_with_dash() {
	SPACERATE_OPTIONS=("--")
	SPACERATE_FILES=("new" "-old")
}

new_starting_with_dash() {
	SPACERATE_OPTIONS=("--")
	SPACERATE_FILES=("-new" "old")
}

declare -A TESTS
TESTS["no_diff"]=":"
TESTS["new_non_existent"]=":"
TESTS["old_non_existent"]=":"
TESTS["old_starting_with_dash"]="old_starting_with_dash"
TESTS["new_starting_with_dash"]="new_starting_with_dash"

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TESTS_DIR="$SCRIPT_DIR/spacerate-tests"
GOLDEN_DATA_DIR="$SCRIPT_DIR/spacerate-golden"

test_start() {
	local test_name="$1"
	local test_dir="$TESTS_DIR/$test_name"
	mkdir -p -- "$test_dir"

	SPACERATE_OPTIONS=()
	SPACERATE_FILES=("new" "old")

	pushd "$test_dir" > /dev/null
}

reverse_array() {
    declare -n arr="$1" rev="$2"
    for i in "${arr[@]}"
    do
        rev=("$i" "${rev[@]}")
    done
}

test_end() {
	local test_name="$1"

	local new_n_stdout="$SCRIPT_DIR/new_normal.stdout"
	local new_n_stderr="$SCRIPT_DIR/new_normal.stderr"
	"$SCRIPT_DIR/spacerate.sh" "${SPACERATE_OPTIONS[@]}" "${SPACERATE_FILES[@]}" \
		1> "$new_n_stdout" 2> "$new_n_stderr"

	local new_r_stdout="$SCRIPT_DIR/new_reversed.stdout"
	local new_r_stderr="$SCRIPT_DIR/new_reversed.stderr"
	local REVERSED_FILES=()
	reverse_array SPACERATE_FILES REVERSED_FILES
	"$SCRIPT_DIR/spacerate.sh" "${SPACERATE_OPTIONS[@]}" "${REVERSED_FILES[@]}" \
		1> "$new_r_stdout" 2> "$new_r_stderr"

	popd > /dev/null

	diff_or_warn "$test_name (normal)" "$GOLDEN_DATA_DIR/$test_name/normal_stdout" "$new_n_stdout"
	diff_or_warn "$test_name (normal)" "$GOLDEN_DATA_DIR/$test_name/normal_stderr" "$new_n_stderr"
	diff_or_warn "$test_name (reversed)" "$GOLDEN_DATA_DIR/$test_name/reversed_stdout" "$new_r_stdout"
	diff_or_warn "$test_name (reversed)" "$GOLDEN_DATA_DIR/$test_name/reversed_stderr" "$new_r_stderr"
}

source "$SCRIPT_DIR/test_harness.sh"
