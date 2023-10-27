#!/usr/bin/env bash
# BIBLIOGRAFIA
# https://tldp.org/LDP/abs/html/tests.html
set -eu
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

	>&2 echo "Usage: $PROGRAM_NAME [options] [dir...]"
	>&2 printf "\n"
	>&2 echo "Options:"
	>&2 echo -e "\t-h:\tShows this message"
	>&2 echo -e "\t-n PATTERN:\tFilter files by name according to the pattern"
	>&2 echo -e "\t-d N:\tFilter directories by date of modification"
	>&2 echo -e "\t-s N:\tFilter directories by file size"
	>&2 echo -e "\t-r:\tPrint in reverse order"
	>&2 echo -e "\t-a:\tOrder by file name"
	>&2 echo -e "\t-l N:\tOnly show up to N lines"

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
OPTIONS="${@:1:OPTIND-1}"
shift $((OPTIND-1))

if [ "$#" -lt 1 ]; then
	help "Not enough arguments"
fi


if [ "$NAME_SORT" = true ] ; then
	SORT_OPTS+=("-k" "2")
else
	SORT_OPTS+=("-n" "-k" "1")
	[ "$REVERSE_SORT" = true ] && REVERSE_SORT=false || REVERSE_SORT=true
fi

if [ "$REVERSE_SORT" = true ] ; then
	SORT_OPTS+=("-r")
fi

echo "SIZE" "NAME" "$(date +%Y%m%d)" "${OPTIONS[@]}"

# TODO: Isto deve usar bytes (-b) ou block size
find "$@" "${FIND_OPTS[@]}" -type d -print0 2>/dev/null | \
while IFS= read -r -d $'\0' path; do
	if find "$path" >/dev/null 2>&1; then
		du -bd 0 "$path" 2>/dev/null || true
	else
		echo -e "NA\t$path"
	fi
done | \
# NOTE: Sorting with `en_US.UTF-8` uses the unicode collation algorithm
sort "${SORT_OPTS[@]}" | \
( [ "${#HEAD_OPTS[@]}" -lt 1 ] && cat || head "${HEAD_OPTS[@]}" )
