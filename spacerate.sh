#!/usr/bin/env bash
# BIBLIOGRAFIA
# https://tldp.org/LDP/abs/html/tests.html
set -eu
PROGRAM_NAME="$0"



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


while getopts ":hras:l:" o; do
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

declare -A SPACECHECK1
declare -A SPACECHECK2

while IFS=$'\n' read -r line; do
    SPACECHECK1[$(echo $line | awk '{print $2}')]=$(echo $line | awk '{print $1}')
done < <(tail -n +2 "$1")

while IFS=$'\n' read -r line; do
    SPACECHECK2[$(echo $line | awk '{print $2}')]=$(echo $line | awk '{print $1}')
done < <(tail -n +2 "$2")

declare -A DIRECTORIES

for key in "${!SPACECHECK1[@]}"; do
    DIRECTORIES[$key]=1
done

for key in "${!SPACECHECK2[@]}"; do
    DIRECTORIES[$key]=1
done


echo SIZE NAME

for key in "${!DIRECTORIES[@]}"; do
    if [ -z "${SPACECHECK2[$key]+x}" ]; then
        echo -e "${SPACECHECK1[$key]}\t$key NEW"
    elif [ -z "${SPACECHECK1[$key]+x}" ]; then
        echo -e "-${SPACECHECK2[$key]}\t$key REMOVED"
    else
        echo -e "$((${SPACECHECK1[$key]} - ${SPACECHECK2[$key]}))\t$key"
    fi
done | sort -n -r -k 1