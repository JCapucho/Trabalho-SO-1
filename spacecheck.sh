#!/usr/bin/env bash
# BIBLIOGRAFIA
# https://tldp.org/LDP/abs/html/tests.html
set -o pipefail
PROGRAM_NAME="$0"

FIND_OPTS=()
NAME_SORT=false
REVERSE_SORT=false
SORT_OPTS=()
HEAD_OPTS=()
POSITIONAL_ARGS=()

help() {
	if [ ! -z "${1+x}" ]; then
		>&2 echo "Error: $1"
	fi

	>&2 echo "Usage: $(basename "$PROGRAM_NAME") [options] [dir...]"
	>&2 printf "\n"
	>&2 echo "Options:"
	>&2 echo -e "\t-h:          Shows this message"
	>&2 echo -e "\t-n PATTERN:  Filter files by name according to the pattern"
	>&2 echo -e "\t-d N:        Filter files by date of modification"
	>&2 echo -e "\t-s N:        Filter files by file size"
	>&2 echo -e "\t-r:          Print in reverse order"
	>&2 echo -e "\t-a:          Order by file name"
	>&2 echo -e "\t-l N:        Only show up to N lines"

	if [ -z "${1+x}" ]; then
		exit 0;
	else
		exit 1;
	fi
}

while getopts ":hran:d:s:l:" o; do
    case "${o}" in
		h)
			help
			;;
		n)
			pattern="$OPTARG"
			if [ -z "$pattern" ]; then
				help "Missing argument for \`-$o\`"
			fi
			FIND_OPTS+=("-regextype" "posix-extended" "-regex" "^.*/$pattern$")
			;;
		d)
			data="$OPTARG"
			if [ -z "$data" ]; then
				help "Missing argument for \`-$o\`"
			fi
			timestamp="@$(date -d "$data" +%s)"
			FIND_OPTS+=("-newermt" "$timestamp")
			;;
		s)
			tamanho="$OPTARG"
			if [ -z "$tamanho" ]; then
				help "Missing argument for \`-$o\`"
			fi
			if [[ "${tamanho:0-1}" =~ ^[0-9]+$ ]]; then
				tamanho+="c"
			fi
			if [[ "${tamanho:0:1}" =~ ^[0-9]+$ ]]; then
				tamanho="+$tamanho"
			fi
			FIND_OPTS+=("-size" "$tamanho")
			;;
		r)
			REVERSE_SORT=true
			;;
		a)
			NAME_SORT=true
			;;
		l)
			linhas="$OPTARG"
			if [ -z "$linhas" ]; then
				help "Missing argument for \`-$o\`"
			fi
			HEAD_OPTS+=("-n" "$linhas")
			;;
		: )
			help "Missing argument"
			;;
		? )
			help "Unknown option"
			;;
		* )
			help "Unknown option \`-$o\`"
			;;
    esac
done

LAST_OPTION_INDEX=$((OPTIND-1))
# Don't record the argument separator `--` in the used options
if [ "${!LAST_OPTION_INDEX}" == "--" ]; then
	OPTIONS="${@:1:OPTIND-2}"
else
	OPTIONS="${@:1:OPTIND-1}"
fi
shift $((OPTIND-1))

if [ "$#" -lt 1 ]; then
	help "Not enough arguments"
fi

NAME_REVERSE_SUFFIX=$([ "$REVERSE_SORT" = false ] && echo "" || echo "r")
SIZE_REVERSE_SUFFIX=$([ "$REVERSE_SORT" = true ] && echo "" || echo "r")

SORT_BY_NAME=("-k" "2$NAME_REVERSE_SUFFIX")
SORT_BY_SIZE=("-k" "1,1n$SIZE_REVERSE_SUFFIX")

if [ "$NAME_SORT" = true ] ; then
	SORT_OPTS+=( "${SORT_BY_NAME[@]}" "${SORT_BY_SIZE[@]}" )
else
	SORT_OPTS+=( "${SORT_BY_SIZE[@]}" "${SORT_BY_NAME[@]}" )
fi

DIRS_TO_SEARCH=()

for dir in "$@"; do
	if [ ! -d "$dir" ]; then
		1>&2 echo "ERROR: \"$dir\" does not exist"
	fi
	case "$dir" in
		-*)
			if [ ! -d "$dir" ]; then
				1>&2 echo "+note: did you mean to pass an argument?"
				1>&2 echo "       all arguments must precede the directory paths"
			fi
			# Add `./` to directories beginning with a dash (`-`), so that find
			# doesn't mistake them, for options.
			DIRS_TO_SEARCH+=("./$dir");;
		*)
			DIRS_TO_SEARCH+=("$dir");;
	esac
done

echo "SIZE" "NAME" "$(date +%Y%m%d)" "${OPTIONS[@]}"

find "${DIRS_TO_SEARCH[@]}" -type d -print0 2>/dev/null | \
while IFS= read -r -d $'\0' path; do
	size=$(find "$path" "${FIND_OPTS[@]}" -type f -print0  2>/dev/null | \
		   du -b --files0-from=- -cs 2>/dev/null | \
		   cut -f1 | tail -n1)
	if [ "$?" -ne 0 ]; then
		size="NA"
	fi

	echo -e "$size\t$path"
done | \
# NOTE: Sorting with `en_US.UTF-8` uses the unicode collation algorithm
sort "${SORT_OPTS[@]}" | \
( [ "${#HEAD_OPTS[@]}" -lt 1 ] && cat || head "${HEAD_OPTS[@]}" )
