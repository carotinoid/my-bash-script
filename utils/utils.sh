function msg {
    echo >&2 -e "${1-}"
}

function msg_n {
    echo >&2 -e -n "${1-}"
}

function If_exist_then_delete {
    if [[ -f $1 ]]; then
        rm $1
    fi
}
function Print_line {
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
function Erase {
    for ((i=0;i<${1-1};i++)); do
        msg_n "\b \b"
    done
}

function Clear_end {
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

function die {
    local msg=$1
    local code=${2-1}
    msg "$msg"
    exit "$code"
}

function setup_colors {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

function Check_hash {
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

function get_extension {
    local file_name=$1
    echo "${file_name##*.}"
}
