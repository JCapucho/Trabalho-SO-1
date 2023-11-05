#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TESTS_DIR="$SCRIPT_DIR/tests"
GOLDEN_DATA_DIR="$SCRIPT_DIR/spacecheck-golden"

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

	SPACECHECK_DIRS=()
	SPACECHECK_OPTIONS=()
	FAKED_DATE="2023/11/01"

	pushd "$test_dir" > /dev/null
}

diff_or_warn() {
	local test_name="$1"
	local ref_file="$2"
	local new_file="$3"

	if [ -f "$ref_file" ]; then
		"$DIFF_TOOL" "$ref_file" "$new_file"

		if [ "$?" -ne 0 ]; then
			echo "$test_name: FAILED"
			1>&2 echo "Error: Result differs from golden data"
			1>&2 echo "The new result was stored in $new_file"
			exit 1
		fi

		rm "$new_file"
	else
		1>&2 echo "Warning: No golden data found to compare \"$new_file\" for \"$test_name\""
		mv "$new_file" "$ref_file"
	fi
}

test_end() {
	popd > /dev/null

	local test_name="$1"

	if [ "${#SPACECHECK_DIRS[@]}" -eq 0 ]; then
		SPACECHECK_DIRS+=("$test_name")
	else
		for i in "${!SPACECHECK_DIRS[@]}"; do
			SPACECHECK_DIRS[$i]="$test_name/${SPACECHECK_DIRS[$i]}"
		done
	fi

	local new_stdout="$SCRIPT_DIR/new.stdout"
	local new_stderr="$SCRIPT_DIR/new.stderr"

	pushd "$TESTS_DIR" > /dev/null
	faketime "$FAKED_DATE" "$SCRIPT_DIR/spacecheck.sh" \
		"${SPACECHECK_OPTIONS[@]}" "${SPACECHECK_DIRS[@]}" 1> "$new_stdout" 2> "$new_stderr"
	popd > /dev/null

	diff_or_warn "$test_name" "$GOLDEN_DATA_DIR/$test_name/stdout" "$new_stdout"
	# diff_or_warn "$test_name" "$GOLDEN_DATA_DIR/$test_name/stderr"

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
