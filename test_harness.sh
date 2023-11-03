#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TESTS_DIR="$SCRIPT_DIR/tests"
GOLDEN_DATA_DIR="$SCRIPT_DIR/golden-data"

DIFF_TOOL="diff"

if command -v delta &> /dev/null; then
	DIFF_TOOL="delta"
fi

mkdir -p "$TESTS_DIR"
mkdir -p "$GOLDEN_DATA_DIR"

test_start() {
	local test_name="$1"
	local test_dir="$TESTS_DIR/$test_name"

	if [ -d "$test_dir" ]; then
		chmod -R +x "$test_dir"
		rm -rf "$test_dir"
	fi

	mkdir -p "$test_dir"

	SPACECHECK_OPTIONS=()
	FAKED_DATE="2023/11/01"

	pushd "$test_dir" > /dev/null
}

test_end() {
	popd > /dev/null

	local test_name="$1"
	pushd "$TESTS_DIR" > /dev/null
	local output="$(faketime "$FAKED_DATE" "$SCRIPT_DIR/spacecheck.sh" "${SPACECHECK_OPTIONS[@]}" "$test_name")"
	popd > /dev/null

	local golden_data_file="$GOLDEN_DATA_DIR/$test_name"

	if [ -f "$golden_data_file" ]; then
		echo "$output" | "$DIFF_TOOL" "$golden_data_file" -

		if [ "$?" -ne 0 ]; then
			local rejected_test_file="$SCRIPT_DIR/rejected-test.data"
			echo "$test_name: FAILED"
			1>&2 echo "Error: Result differs from golden data"
			1>&2 echo "Saving new data to rejected-test.data"
			echo "$output" > "$rejected_test_file"
			exit 1
		fi
	else
		1>&2 echo "Warning: No golden data found for \"$test_name\""
		echo "$output" > "$golden_data_file"
	fi

	SPACECHECK_OPTIONS=()

	echo "$test_name: PASSED"
}

create_test_file() {
	local path="$1"
	local size="$2"

	mkdir -p "$( dirname "$path" )"
	printf '%*s\n' $((size - 1)) "=" > "$path"
}

runner() {
	local test_name="$1"
	test_start "$test_name"
	"$2"
	test_end "$test_name"
}

source "$SCRIPT_DIR/tests.sh"

if [ "$#" -lt 1 ]; then
	for test in "${!TESTS[@]}"; do
		runner "$test" "${TESTS[$test]}"
	done
else
	for test in "$@"; do
		if [ -z ${TESTS[$test]+x} ]; then
			1>&2 "ERROR: Unknown test \"$test\""
			exit 1
		fi

		runner "$test" "${TESTS[$test]}"
	done
fi
