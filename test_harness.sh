DIFF_TOOL="diff"

if command -v delta &> /dev/null; then
	DIFF_TOOL="delta"
fi

mkdir -p "$TESTS_DIR"
mkdir -p "$GOLDEN_DATA_DIR"

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
		mkdir -p -- "$(dirname -- "$ref_file")"
		mv -- "$new_file" "$ref_file"
	fi
}

create_test_file() {
	local path="$1"
	local size="$2"

	mkdir -p -- "$( dirname -- "$path" )"
	dd if=/dev/zero "of=$path" "bs=$size" count=1 2>/dev/null
}

runner() {
	local test_name="$1"
	test_start "$test_name"
	"$2"
	test_end "$test_name"

	echo "$test_name: PASSED"
}

if [ "$#" -lt 1 ]; then
	for test in "${!TESTS[@]}"; do
		runner "$test" "${TESTS[$test]}"
	done
else
	for test in "$@"; do
		if [ -z ${TESTS[$test]+x} ]; then
			1>&2 echo "ERROR: Unknown test \"$test\""
			exit 1
		fi

		runner "$test" "${TESTS[$test]}"
	done
fi
