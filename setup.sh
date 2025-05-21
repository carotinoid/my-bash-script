#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

echo '# ps simple alias
alias run="'$script_dir/run.sh'"
alias stress="'$script_dir/stress.sh'"' >> ~/.bashrc

echo "The alias commands were added in ~/.bashrc"