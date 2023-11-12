#!/usr/bin/env bash
PROGRAM_NAME="$0"

NAME_SORT=false
REVERSE_SORT=false
SORT_OPTS=()
HEAD_OPTS=()

help() {
	if [ ! -z "${1+x}" ]; then
		>&2 echo "Error: $1"
	fi

	>&2 echo "Usage: $(basename "$PROGRAM_NAME") [options] <new> <old>"
	>&2 printf "\n"
	>&2 echo "Options:"
	>&2 echo -e "\t-h:          Shows this message"
	>&2 echo -e "\t-r:          Print in reverse order"
	>&2 echo -e "\t-a:          Order by file name"
	>&2 echo -e "\t-l N:        Only show up to N lines"

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

NAME_REVERSE_PREFIX=$([ "$REVERSE_SORT" = false ] && echo "" || echo "r")
SIZE_REVERSE_PREFIX=$([ "$REVERSE_SORT" = true ] && echo "" || echo "r")

SORT_BY_NAME=("-k" "2$NAME_REVERSE_PREFIX")
SORT_BY_SIZE=("-k" "1,1n$SIZE_REVERSE_PREFIX")

if [ "$NAME_SORT" = true ] ; then
	SORT_OPTS+=( "${SORT_BY_NAME[@]}" "${SORT_BY_SIZE[@]}" )
else
	SORT_OPTS+=( "${SORT_BY_SIZE[@]}" "${SORT_BY_NAME[@]}" )
fi

declare -A SPACECHECK_NEW
declare -A SPACECHECK_OLD

NEWFILE="$1"
OLDFILE="$2"

declare -A DIRECTORIES

while IFS= read -r -d $'\n' line; do
	size=$(echo "$line" | cut -f1)
	name=$(echo "$line" | cut -f2-)
	SPACECHECK_NEW["$name"]="$size"
	DIRECTORIES["$name"]=1
done < <(tail -n +2 -- "$NEWFILE")

while IFS= read -r -d $'\n' line; do
	size=$(echo "$line" | cut -f1)
	name=$(echo "$line" | cut -f2-)
	SPACECHECK_OLD["$name"]="$size"
	DIRECTORIES["$name"]=1
done < <(tail -n +2 -- "$OLDFILE")

echo SIZE NAME

for key in "${!DIRECTORIES[@]}"; do
	old_size="${SPACECHECK_OLD[$key]}"
	new_size="${SPACECHECK_NEW[$key]}"
	if [ -z "$old_size" ]; then
		echo -e "$new_size\t$key\tNEW"
	elif [ -z "$new_size" ]; then
		if [ "$old_size" == "0" ] || [ "$old_size" == "NA" ]; then
			display_size="$old_size"
		else
			display_size="-$old_size"
		fi

		echo -e "$display_size\t$key\tREMOVED"
	elif [ "$old_size" == "NA" ] || [ "$new_size" == "NA" ]; then
		echo -e "NA\t$key"
	else
		diff=$((new_size - old_size))
		echo -e "$diff\t$key"
	fi
done | \
# NOTE: Sorting with `en_US.UTF-8` uses the unicode collation algorithm
sort "${SORT_OPTS[@]}" | \
( [ "${#HEAD_OPTS[@]}" -lt 1 ] && cat || head "${HEAD_OPTS[@]}" )
