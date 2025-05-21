#!/usr/bin/env bash

###### Basic functions ######

msg()  {
    echo >&2 -e "${1-}"
}

msg_n()  {
    echo >&2 -e -n "${1-}"
}

If_exist_then_delete()  {
    if [[ -f $1 ]]; then
        rm $1
    fi
}
Print_line()  {
    local terminal_width=$(tput cols)
    local message=${1-""}
    local sep=${2-"="}
    local message_length=${#message}
    local total_equals=$(( (terminal_width - message_length) / 2 ))
    if (( (terminal_width - message_length) % 2 != 0 )); then
        total_equals=$((total_equals + 1))
    fi
    local post_equals=$total_equals
    if (( total_equals + total_equals + message_length > terminal_width )); then
        post_equals=$((total_equals - 1))
    fi
    printf '%*s%s%*s\n' $total_equals '' "$message" $post_equals '' | tr ' ' $sep
}
Erase()  {
    for ((i=0;i<${1-1};i++)); do
        msg_n "\b \b"
    done
}

Clear_end()  {
    local str=$1
    while true; do
        if [ "${str: -1}" = $'\n' -o "${str: -1}" = ' ' ]; then
            str=${str%?}
        else
            break
        fi
    done
    echo $str
}

die()  {
    local msg=$1
    local code=${2-1}
    msg "$msg"
    exit "$code"
}

setup_colors()  {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

Check_hash()  {
    local file_path=$1
    local file_name=$2
    local hash_dir=${3:-$TEMP}

    mkdir -p "$hash_dir"

    local file_hash=$(md5sum "$file_path"/"$file_name" | awk '{print $1}')
    local hash_file="$file_name.hash"

    if [[ -f "$hash_dir/$hash_file" ]]; then
        local stored_hash=$(cat "$hash_dir/$hash_file")

        if [[ "$file_hash" == "$stored_hash" ]]; then
            echo "1"
        else
            echo "$file_hash" > "$hash_dir/$hash_file"
            echo "2"
        fi
    else
        echo "$file_hash" > "$hash_dir/$hash_file"
        echo "0"
    fi
}

get_extension()  {
    local file_name=$1
    echo "${file_name##*.}"
}

###### End ######

set -Euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

WORKSPACE=$script_dir
TEMP=$WORKSPACE/.ps
SRC_TARGET=$WORKSPACE
SRC_OTHER=$WORKSPACE/src #input, output

FILE_CODE=main.cpp

USE_EXIST_INPUT=0
CHECK_TIMEOUT=0
ExecutionTime=2
VERSION=0.0.2
OLD_IFS=$IFS


usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f FILE] [-i] [-t TIME]
A basic shell script to compile and execute C++ files.
  
Options:
  -h, --help       Display this help message.
  -v, --version    Show the script version.
  -f, --file       Specify a C++ file to compile and run.
                   (Default: main.cpp)
  -i, --input      Use input.txt as input data.
  -t, --time       Set the execution time limit (in seconds).
                   (Default: 2 seconds)
  -d, --direct     Direct run.

Special Options:
  --flush          Remove all cached and generated files.
  --no-color       Disable color output in the terminal.
  --verbose        Enable detailed debug messages.
  
EOF
    exit 0
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    IFS=$OLD_IFS
    if [[ -s $SRC_OTHER/input.txt ]]; then
        Print_line "Input" 
        msg "$(cat $SRC_OTHER/input.txt)"
        Print_line 
    fi
    if (( CHECK_TIMEOUT )); then
        Print_line "TIMEOUT" 
        msg "Program cannot be executed successfully in ${RED}$ExecutionTime${NOFORMAT} seconds."
        Print_line
    fi
    if [[ -s $SRC_OTHER/output.txt ]]; then
        Print_line "Output" 
        msg "$(cat $SRC_OTHER/output.txt)"
        Print_line
    fi
    if [[ -s $TEMP/exec_err ]]; then
        Print_line "ERROR" 
        msg "$(cat $TEMP/exec_err)"
        Print_line
    fi
}

parse_params() {
    while :; do
        case "${1-}" in
        --no-color) NO_COLOR=1 ;;
        --verbose) set -x ;;
        --flush) 
        rm $TEMP/*
        msg "The hash files and execution files were flushed."
        exit 0
        ;;
        -v | --version)
        msg "version: $VERSION"
        exit 0
        ;;
        -h | --help) usage ;;
        -i | --input) USE_EXIST_INPUT=1 ;; 
        -f | --file) 
        FILE_CODE="${2-}"
        shift ;;
        -t | --time)
        ExecutionTime="${2-}"
        shift ;;
        -d | --direct)
        $TEMP/$FILE_CODE.run
        ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done
    args=("$@")
    return 0
}

# Setup
parse_params "$@"
setup_colors
trap cleanup SIGINT SIGTERM ERR EXIT
If_exist_then_delete $SRC_OTHER/output.txt
If_exist_then_delete $TEMP/exec_err
If_exist_then_delete $TEMP/compile_err
If_exist_then_delete $TEMP/compile_succ

# Check update
need_compile=0
CompileDoneNumofBackspace=10

checking_hash=$(Check_hash $SRC_TARGET $FILE_CODE)
if [[ $checking_hash -eq 0 ]]; then
    msg_n "No hash, ${ORANGE}compiling.${NOFORMAT}"
    need_compile=1
elif [[ $checking_hash -eq 1 ]]; then
    msg "Execution file already exists, ${GREEN}no compile${NOFORMAT}."
else
    msg_n "Updated, ${ORANGE}compiling.${NOFORMAT}"
    need_compile=1
fi

# Compile
time_startCompile=$(date +%s.%3N)
if (( need_compile )); then
    g++ -o $TEMP/$FILE_CODE.run -O2 -DDEBUGTOOLS -Wno-unused-but-set-variable -Wno-unused-variable  -lm -static -std=c++2a -g $SRC_TARGET/$FILE_CODE 2> $TEMP/compile_err &
    pid=$!
    while kill -0 $pid 2>/dev/null; do
        sleep 1
        (( CompileDoneNumofBackspace++ ))
        msg_n "${ORANGE}.${NOFORMAT}"
    done
    Erase $CompileDoneNumofBackspace
    if [[ -s $TEMP/compile_err ]]; then
        msg "${RED}Compile incomplete!${NOFORMAT}"
        cat $TEMP/compile_err
        rm $TEMP/$FILE_CODE.hash
        die "${RED}ERROR OCCURED.${NOFORMAT}"
    fi
    time_endCompile=$(date +%s.%3N)
    time_elapsedCompile=$(echo "$time_endCompile - $time_startCompile" | bc)
    msg_n "${GREEN}Compile Done!${NOFORMAT} "
    msg_n "${GREEN}($time_elapsedCompile"
    msg "s)${NOFORMAT}"
fi

# Input
if ! (( USE_EXIST_INPUT )); then
    cat > $SRC_OTHER/input.txt
fi

# Execution
timeout $ExecutionTime $TEMP/$FILE_CODE.run < $SRC_OTHER/input.txt > $SRC_OTHER/output.txt 2> $TEMP/exec_err
if [[ $? -eq 124 ]]; then
    CHECK_TIMEOUT=1
    msg "${RED}TIMEOUT OCCURED. ($ExecutionTime seconds)${NOFORMAT}"
fi