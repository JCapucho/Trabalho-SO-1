#!/usr/bin/env bash
# BIBLIOGRAFIA
# https://tldp.org/LDP/abs/html/tests.html
PROGRAM_NAME="$0"

NAME_SORT=false
REVERSE_SORT=false
SORT_OPTS=()
HEAD_OPTS=()

help() {
	if [ ! -z "${1+x}" ]; then
		>&2 echo "Error: $1"
	fi

	>&2 echo "Usage: $PROGRAM_NAME [options] <old> <new> "
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
shift $((OPTIND-1))

if [ $# -lt 2 ]; then
	help "Missing arguments"
elif [ $# -gt 2 ]; then
	help "Too many arguments"
elif [ ! -f "$1" ]; then
    help "File \`$1\` does not exist"
elif [ ! -f "$2" ]; then
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

NEWESTFILE="$2"
OLDESTFILE="$1"

# if [ $(head "$1" | awk '{print $3}') -ge $(head "$2" | awk '{print $3}') ]; then
# 	NEWESTFILE="$1"
# 	OLDESTFILE="$2"
# else
# 	NEWESTFILE="$2"
# 	OLDESTFILE="$1"
# fi

while IFS=$'\n' read -r line; do
	size=$(echo $line | cut -d ' ' -f1)
	name=$(echo $line | cut -d ' ' -f2-)
	SPACECHECK_NEWEST["$name"]="$size"
done < <(tail -n +2 "$NEWESTFILE")

while IFS=$'\n' read -r line; do
	size=$(echo $line | cut -d ' ' -f1)
	name=$(echo $line | cut -d ' ' -f2-)
  	SPACECHECK_OLDEST["$name"]="$size"
done < <(tail -n +2 "$OLDESTFILE")

declare -A DIRECTORIES

for key in "${!SPACECHECK_NEWEST[@]}"; do
	DIRECTORIES["$key"]=1
done

for key in "${!SPACECHECK_OLDEST[@]}"; do
	DIRECTORIES["$key"]=1
done

echo SIZE NAME

for key in "${!DIRECTORIES[@]}"; do
	old_size="${SPACECHECK_OLDEST[$key]}"
	new_size="${SPACECHECK_NEWEST[$key]}"
	if [ -z "$old_size" ]; then
		echo -e "$new_size\t$key\tNEW"
  	elif [ -z "$new_size" ]; then
		echo -e "-$old_size\t$key\tREMOVED"
  	else
		diff=$((new_size - old_size))
		echo -e "$diff\t$key"
	fi
done | \
# NOTE: Sorting with `en_US.UTF-8` uses the unicode collation algorithm
sort "${SORT_OPTS[@]}" | \
( [ "${#HEAD_OPTS[@]}" -lt 1 ] && cat || head "${HEAD_OPTS[@]}" )
