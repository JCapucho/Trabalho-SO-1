empty_root() {
	: # Do nothing
}

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

declare -A TESTS
TESTS["empty_root"]="empty_root"
TESTS["quoting_test"]="quoting_test"
TESTS["size_sort_reverse"]="size_sort_reverse"
TESTS["name_sort"]="name_sort"
TESTS["name_sort_reverse"]="name_sort_reverse"
TESTS["same_size_root"]="same_size_root"
