#!/usr/bin/env bash

function pushd() { command pushd "$@" > /dev/null || return 1 ; }
function popd() { command popd > /dev/null || return 1; }

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

green() { echo -en "${GREEN}$1${NC}" ; }
red () { echo -en "${RED}$1${NC}" ; }

function hr() {
    local char=${1:-=}
    local cols=${2:-$COLUMNS}
    if [ -z "$cols" ]; then
        cols=$(tput cols)
    fi
    printf "%${cols}s" | tr ' ' "$char"
}

function check_dependencies() {
    # And array has to be passed as a parameter
    # declare -a dependencies=("${!1}")
    fail=0

    # for dependency in "${dependencies[@]}"; do
    for dependency in "$@"; do
    	echo -n "Checking $dependency... "
        if command -v "$dependency" &> /dev/null; then
            green "$dependency"
            echo " is installed"
        else
            red "$dependency is not installed\n"
            fail=1
        fi
        sleep 0.1
    done

    if [ $fail -eq 1 ]; then
        red "Please install the dependencies and try again\n"
        return 1
    fi

    return 0
}
