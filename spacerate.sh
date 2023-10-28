#!/usr/bin/env bash
# BIBLIOGRAFIA
# https://tldp.org/LDP/abs/html/tests.html
set -eu
PROGRAM_NAME="$0"

NAME_SORT=false
REVERSE_SORT=false
SORT_OPTS=()
HEAD_OPTS=()

help() {
	if [ ! -z "${1+x}" ]; then
		>&2 echo "Error: $1"
	fi

	>&2 echo "Usage: $PROGRAM_NAME [options] <file1> <file2> "
	>&2 printf "\n"
	>&2 echo "Options:"
	>&2 echo -e "\t-h:\tShows this message"
	>&2 echo -e "\t-r:\tPrint in reverse order"
	>&2 echo -e "\t-a:\tOrder by file name"
	>&2 echo -e "\t-l N:\tOnly show up to N lines"

	if [ -z "${1+x}" ]; then
		exit 0;
	else
		exit 1;
	fi
}


while getopts ":hral:" o; do
    case "${o}" in
		h)
			help
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

if [ $# -lt 2 ]; then
    help "Missing arguments"
fi

if [ $# -gt 2 ]; then
		help "Too many arguments"
fi

if [ ! -f "$1" ]; then
    help "File \`$1\` does not exist"
fi

if [ ! -f "$2" ]; then
    help "File \`$2\` does not exist"
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

declare -A SPACECHECK_NEWEST
declare -A SPACECHECK_OLDEST

NEWESTFILE=""
OLDESTFILE=""

if [ $(head "$1" | awk '{print $3}') -ge $(head "$2" | awk '{print $3}') ]; then
	NEWESTFILE="$1"
	OLDESTFILE="$2"
else
	NEWESTFILE="$2"
	OLDESTFILE="$1"
fi

while IFS=$'\n' read -r line; do
  SPACECHECK_NEWEST[$(echo $line | awk '{print $2}')]=$(echo $line | awk '{print $1}')
done < <(tail -n +2 "$NEWESTFILE")

while IFS=$'\n' read -r line; do
  SPACECHECK_OLDEST[$(echo $line | awk '{print $2}')]=$(echo $line | awk '{print $1}')
done < <(tail -n +2 "$OLDESTFILE")

declare -A DIRECTORIES

for key in "${!SPACECHECK_NEWEST[@]}"; do
	DIRECTORIES[$key]=1
done

for key in "${!SPACECHECK_OLDEST[@]}"; do
	DIRECTORIES[$key]=1
done


echo SIZE NAME

for key in "${!DIRECTORIES[@]}"; do
	if [ -z "${SPACECHECK_OLDEST[$key]+x}" ]; then
		echo -e "${SPACECHECK_NEWEST[$key]}\t$key NEW"
  elif [ -z "${SPACECHECK_NEWEST[$key]+x}" ]; then
		echo -e "-${SPACECHECK_OLDEST[$key]}\t$key REMOVED"
  else
		echo -e "$((${SPACECHECK_NEWEST[$key]} - ${SPACECHECK_OLDEST[$key]}))\t$key"
	fi
done | \
# NOTE: Sorting with `en_US.UTF-8` uses the unicode collation algorithm
sort "${SORT_OPTS[@]}" | \
( [ "${#HEAD_OPTS[@]}" -lt 1 ] && cat || head "${HEAD_OPTS[@]}" )