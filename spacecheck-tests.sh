#!/usr/bin/env bash
set -u

quoting_test() {
	create_test_file "simple/file" 4
	create_test_file "with spaces/file" 2
	create_test_file 'with " quotes/file' 7
}

size_sort_reverse() {
	SPACECHECK_OPTIONS=("-r")
	quoting_test
}

name_sort() {
	SPACECHECK_OPTIONS=("-a")
	quoting_test
}

name_sort_reverse() {
	SPACECHECK_OPTIONS=("-a" "-r")
	quoting_test
}

same_size_root() {
	create_test_file "simple/file" 4
}

no_execute_permision_file() {
	create_test_file "correct/file" 4
	create_test_file "no_execute/file" 4
	chmod -x "no_execute/file"
}

no_execute_permision_dir() {
	create_test_file "correct/file" 4
	create_test_file "no_execute/file" 4
	chmod -x "no_execute"
}

regex_filter() {
	SPACECHECK_OPTIONS=("-n" ".*\.sh")
	create_test_file "all_filtered/file" 4
	create_test_file "mixed_filtered/file1" 4
	create_test_file "mixed_filtered/file2.sh" 4
	create_test_file "mixed_filtered/file3" 4
	create_test_file "mixed_filtered/file4.sh" 4
}

date_modification_filter() {
	SPACECHECK_OPTIONS=("-d" "Sep 10 10:00")
	create_test_file "all_filtered/file" 4
	touch -d "Sep 10 09:59" "all_filtered/file"

	create_test_file "mixed_filtered/file1" 4
	touch -d "Sep 10 10:01" "mixed_filtered/file1"

	create_test_file "mixed_filtered/file2" 4
	touch -d "Sep 10 10:01" "mixed_filtered/file2"

	create_test_file "mixed_filtered/file3" 4
	touch -d "Sep 10 09:59" "mixed_filtered/file3"

	create_test_file "mixed_filtered/file4" 4
	touch -d "Sep 10 10:01" "mixed_filtered/file4"
}

file_size_filter() {
	SPACECHECK_OPTIONS=("-s" "10")
	create_test_file "all_filtered/file" 9

	create_test_file "mixed_filtered/file1" 14
	create_test_file "mixed_filtered/file2" 4
	create_test_file "mixed_filtered/file3" 26
	create_test_file "mixed_filtered/file4" 4
}

head_3_lines() {
	SPACECHECK_OPTIONS=("-l" "3")
	create_test_file "dir1/file" 9
	create_test_file "dir2/file" 14
	create_test_file "dir3/file" 4
	create_test_file "dir4/file" 26
	create_test_file "dir5/file" 4
}

head_3_lines_reverse() {
	SPACECHECK_OPTIONS=("-l" "3" "-r")
	create_test_file "dir1/file" 9
	create_test_file "dir2/file" 14
	create_test_file "dir3/file" 4
	create_test_file "dir4/file" 26
	create_test_file "dir5/file" 4
}

combined_filters() {
	SPACECHECK_OPTIONS=("-d" "Sep 10 10:00" "-s" "10" "-n" ".*\.sh")
	create_test_file "all_filtered/file" 9
	touch -d "Sep 10 09:59" "all_filtered/file"

	create_test_file "mixed_filtered/file1" 14
	touch -d "Sep 10 09:59" "mixed_filtered/file1"

	create_test_file "mixed_filtered/file2" 4
	touch -d "Sep 10 10:01" "mixed_filtered/file2"

	create_test_file "mixed_filtered/file3.sh" 26
	touch -d "Sep 10 10:01" "mixed_filtered/file3"

	create_test_file "mixed_filtered/file4" 4
	touch -d "Sep 10 09:59" "mixed_filtered/file4"

	create_test_file "mixed_filtered/file5" 40
	touch -d "Sep 10 10:01" "mixed_filtered/file5"
}

argument_seperator() {
	SPACECHECK_OPTIONS=("--")
	SPACECHECK_DIRS=("-n")
	create_test_file "-n/file" 4
	create_test_file "-n/file2" 2
}

non_existent_dir_with_dash() {
	SPACECHECK_DIRS=("simple" "-n")
	create_test_file "simple/file" 4
	create_test_file "simple/file2" 2
}

unknown_option() {
	SPACECHECK_DIRS=("-m")
}

multiple_dirs() {
	SPACECHECK_DIRS=("dir1" "dir2" "dir4")
	create_test_file "dir1/file" 1
	create_test_file "dir2/file" 2
	create_test_file "dir3/file" 3
	create_test_file "dir4/file" 4
}

different_time() {
	FAKED_DATE="2023/11/05"
	create_test_file "dir1/file" 1
	create_test_file "dir1/file" 2
}

declare -A TESTS
TESTS["empty_root"]=":" # The `:` function does nothing (ie. nop)
TESTS["quoting_test"]="quoting_test"
TESTS["size_sort_reverse"]="size_sort_reverse"
TESTS["name_sort"]="name_sort"
TESTS["name_sort_reverse"]="name_sort_reverse"
TESTS["same_size_root"]="same_size_root"
TESTS["no_execute_permision_file"]="no_execute_permision_file"
TESTS["no_execute_permision_dir"]="no_execute_permision_dir"
TESTS["regex_filter"]="regex_filter"
TESTS["date_modification_filter"]="date_modification_filter"
TESTS["file_size_filter"]="file_size_filter"
TESTS["head_3_lines"]="head_3_lines"
TESTS["head_3_lines_reverse"]="head_3_lines_reverse"
TESTS["combined_filters"]="combined_filters"
TESTS["argument_seperator"]="argument_seperator"
TESTS["non_existent_dir_with_dash"]="non_existent_dir_with_dash"
TESTS["unknown_option"]="unknown_option"
TESTS["multiple_dirs"]="multiple_dirs"
TESTS["different_time"]="different_time"

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TESTS_DIR="$SCRIPT_DIR/spacecheck-tests"
GOLDEN_DATA_DIR="$SCRIPT_DIR/spacecheck-golden"

test_start() {
	local test_name="$1"
	local test_dir="$TESTS_DIR/$test_name"

	if [ -d "$test_dir" ]; then
		chmod -R +x -- "$test_dir"
		rm -rf -- "$test_dir"
	fi

	mkdir -p -- "$test_dir"

	SPACECHECK_DIRS=()
	SPACECHECK_OPTIONS=()
	FAKED_DATE="2023/11/01"

	pushd "$test_dir" > /dev/null
}

test_end() {
	popd > /dev/null

	local test_name="$1"

	local new_stdout="$SCRIPT_DIR/new.stdout"
	local new_stderr="$SCRIPT_DIR/new.stderr"

	if [ "${#SPACECHECK_DIRS[@]}" -eq 0 ]; then
		SPACECHECK_DIRS+=("$test_name")
		pushd "$TESTS_DIR" > /dev/null
	else
		pushd "$TESTS_DIR/$test_name" > /dev/null
	fi

	faketime "$FAKED_DATE" "$SCRIPT_DIR/spacecheck.sh" \
		"${SPACECHECK_OPTIONS[@]}" "${SPACECHECK_DIRS[@]}" 1> "$new_stdout" 2> "$new_stderr"
	popd > /dev/null

	diff_or_warn "$test_name" "$GOLDEN_DATA_DIR/$test_name/stdout" "$new_stdout"
	diff_or_warn "$test_name" "$GOLDEN_DATA_DIR/$test_name/stderr" "$new_stderr"
}

source "$SCRIPT_DIR/test_harness.sh"
