#!/usr/bin/env bash
. /root/boj/utils/utils.sh

WORKSPACE=/root/boj/stress
TEMP=/root/boj/stress/.stress
COMPILE_GEN=0
COMPILE_ANSWER=0
COMPILE_SUBMIT=0
VERSION=0.0.1
OLD_IFS=$IFS
FILE_GEN=gen.cpp
FILE_ANSWER=answer.cpp
FILE_SUBMIT=submit.cpp
PRINT_CORRECT=0
ATTEMPTS_LIMIT=300

set -Eeuo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-g FILE] [-a FILE] [-s FILE]
A basic shell script to stress test a program.

    Options:
    -h, --help          Display this help message.
    -v, --version       Show the script version.
    -g, --gen, --generator
                        Specify the generator file.
                        (Default: gen.cpp)
    -a, --answer        Specify the answer file.
                        (Default: answer.cpp)
    -s, --submit, --submission
                        Specify the submission file.
    -m, --more          Print the correct output.
                        (Default: 0)
    -l, --limit         Specify the attmpet limit.
                        (Default: 300)

    Special Options:
    --flush             Remove all cached and generated files.
    --no-color          Disable color output in the terminal.
    --verbose           Enable detailed debug messages.

EOF
    exit 0
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    IFS=$OLD_IFS
    msg_n "${NOFORMAT}"
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
        -g | --gen | --generator)
        FILE_GEN="${2-}"
        shift
        ;;
        -a | --answer)
        FILE_ANSWER="${2-}"
        shift
        ;;
        -s | --submit | --submission)
        FILE_SUBMIT="${2-}"
        shift
        ;;
        -m | --more)
        PRINT_CORRECT=1
        ;;
        -l | --limit)
        ATTEMPTS_LIMIT="${2-}"
        shift
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
trap cleanup SIGINT SIGTERM ERR EXIT
setup_colors
parse_params "$@"
mkdir -p $TEMP

check_hash_gen=$(Check_hash $WORKSPACE $FILE_GEN)
check_hash_answer=$(Check_hash $WORKSPACE $FILE_ANSWER)
check_hash_submit=$(Check_hash $WORKSPACE $FILE_SUBMIT)
submission_extension=$(get_extension $FILE_SUBMIT)

if (( check_hash_gen != 1 )); then
    COMPILE_GEN=1
    msg "Need to compile gen.cpp."
else
    msg "Generator already compiled."
fi
if (( check_hash_answer != 1 )); then
    COMPILE_ANSWER=1
    msg "Need to compile answer.cpp."
else
    msg "Answer already compiled."
fi
if (( check_hash_submit != 1 )); then
    COMPILE_SUBMIT=1
    msg "Need to compile submit.cpp."
else
    msg "Submission already compiled."
fi

if (( COMPILE_GEN )); then
    g++ -o $TEMP/$FILE_GEN.run -O2 -Wall -lm -static -std=c++2a -g $WORKSPACE/$FILE_GEN 2> $TEMP/compile_err 
    msg "Compile done gen.cpp successfully."
fi
if (( COMPILE_ANSWER )); then
    g++ -o $TEMP/$FILE_ANSWER.run -O2 -Wall -lm -static -std=c++2a -g $WORKSPACE/$FILE_ANSWER 2> $TEMP/compile_err 
    msg "Compile done answer.cpp successfully."
fi
if (( COMPILE_SUBMIT )); then
    if [[ $submission_extension == "cpp" ]]; then
        g++ -o $TEMP/$FILE_SUBMIT.run -O2 -Wall -lm -static -std=c++2a -g $WORKSPACE/$FILE_SUBMIT 2> $TEMP/compile_err 
    elif [[ $submission_extension == "c" ]]; then
        gcc -o $TEMP/$FILE_SUBMIT.run -O2 -Wall -lm -static -g $WORKSPACE/$FILE_SUBMIT 2> $TEMP/compile_err 
    elif [[ $submission_extension == "java" ]]; then
        javac $WORKSPACE/$FILE_SUBMIT -d $TEMP
        jar cfe $TEMP/$FILE_SUBMIT.jar $FILE_SUBMIT -C $TEMP .
    elif [[ $submission_extension == "kt" ]]; then
        kotlinc $WORKSPACE/$FILE_SUBMIT -include-runtime -d $TEMP/$FILE_SUBMIT.jar
    elif [[ $submission_extension == "py" ]]; then
        pypy3 -c "import py_compile; py_compile.compile('$WORKSPACE/$FILE_SUBMIT')" 2> $TEMP/compile_err
    else
        msg "Invalid extension."
        exit 1
    fi
    msg "Compile done submit.cpp successfully."
fi

attempts=0
while true; do
    attempts=$((attempts+1))
    # generated_input=$($TEMP/$FILE_GEN.run)
    $TEMP/$FILE_GEN.run > $TEMP/input.txt
    answer_output=$($TEMP/$FILE_ANSWER.run < $TEMP/input.txt)
    if [[ $submission_extension == "cpp" ]]; then 
        submission_output=$($TEMP/$FILE_SUBMIT.run < $TEMP/input.txt)
    elif [[ $submission_extension == "c" ]]; then
        $TEMP/$FILE_SUBMIT.run < $TEMP/input.txt > $TEMP/output.txt
        submission_output=$(cat $TEMP/output.txt)
    elif [[ $submission_extension == "java" ]]; then
        java -cp $TEMP $FILE_SUBMIT < $TEMP/input.txt > $TEMP/output.txt
        submission_output=$(cat $TEMP/output.txt)
    elif [[ $submission_extension == "kt" ]]; then
        java -jar $TEMP/$FILE_SUBMIT.jar < $TEMP/input.txt > $TEMP/output.txt
        submission_output=$(cat $TEMP/output.txt)
    elif [[ $submission_extension == "py" ]]; then
        pypy3 $WORKSPACE/$FILE_SUBMIT < $TEMP/input.txt > $TEMP/output.txt
        submission_output=$(cat $TEMP/output.txt)
    else
        msg "Invalid extension"
        exit 1
    fi
    answer_output=$(Clear_end "$answer_output")
    submission_output=$(Clear_end "$submission_output")
    if [[ $answer_output == $submission_output ]]; then
        msg "Test case $attempts: ${GREEN}Accepted${NOFORMAT}"
        if (( PRINT_CORRECT )); then
            msg "${CYAN}Input: "; msg "$(cat $TEMP/input.txt)${NOFORMAT}"
            msg "${YELLOW}Output: $answer_output${NOFORMAT}"
        fi
    else
        msg "Test case $attempts: ${RED}Wrong Answer${NOFORMAT}"
        msg "${PURPLE}Input: "; msg "$(cat $TEMP/input.txt)${NOFORMAT}"
        msg "${CYAN}Expected: $answer_output${NOFORMAT}"
        msg "${YELLOW}Received: $submission_output${NOFORMAT}"
        die "Found a counter example!"
    fi
    if (( attempts >= ATTEMPTS_LIMIT )); then
        msg "All test cases passed."
        break
    fi
done;
