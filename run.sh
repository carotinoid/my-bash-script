#!/usr/bin/env bash
. /root/boj/utils/utils.sh
WORKSPACE=/root/boj
TEMP=/root/boj/.ps
FILE_CODE=main.cpp
USE_EXIST_INPUT=0
CHECK_TIMEOUT=0
ExecutionTime=2
VERSION=0.0.1
OLD_IFS=$IFS

set -Euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

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
    if [[ -s $WORKSPACE/input.txt ]]; then
        Print_line "Input" 
        msg "$(cat $WORKSPACE/input.txt)"
        Print_line 
    fi
    if (( CHECK_TIMEOUT )); then
        Print_line "TIMEOUT" 
        msg "Program cannot be executed successfully in ${RED}$ExecutionTime${NOFORMAT} seconds."
        Print_line
    fi
    if [[ -s $WORKSPACE/output.txt ]]; then
        Print_line "Output" 
        msg "$(cat $WORKSPACE/output.txt)"
        Print_line
    fi
    if [[ -s $TEMP/exec_err
 ]]; then
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
If_exist_then_delete $WORKSPACE/output.txt
If_exist_then_delete $TEMP/exec_err
If_exist_then_delete $TEMP/compile_err
If_exist_then_delete $TEMP/compile_succ

# Check update
need_compile=0
CompileDoneNumofBackspace=10

checking_hash=$(Check_hash $WORKSPACE $FILE_CODE)
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
    # g++ -o $TEMP/$FILE_CODE.run -O2 -Wall -lm -std=c++2a -Wno-unused-result -g $WORKSPACE/$FILE_CODE 2> $TEMP/compile_err &
    g++ -o $TEMP/$FILE_CODE.run -O2 -Wall -lm -static -std=c++2a -g $WORKSPACE/$FILE_CODE 2> $TEMP/compile_err &
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
    cat > $WORKSPACE/input.txt
fi

# Execution
timeout $ExecutionTime $TEMP/$FILE_CODE.run < $WORKSPACE/input.txt > $WORKSPACE/output.txt 2> $TEMP/exec_err
if [[ $? -eq 124 ]]; then
    CHECK_TIMEOUT=1
    msg "${RED}TIMEOUT OCCURED. ($ExecutionTime seconds)${NOFORMAT}"
fi

