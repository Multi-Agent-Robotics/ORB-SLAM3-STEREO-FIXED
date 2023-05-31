#!/usr/bin/env bash

function pushd() { command pushd "$@" > /dev/null || return 1 ; }
function popd() { command popd > /dev/null || return 1; }

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

red () { echo -en "${RED}$1${NC}" ; }
green() { echo -en "${GREEN}$1${NC}" ; }
yellow() { echo -en "${YELLOW}$1${NC}" ; }
blue() { echo -en "${BLUE}$1${NC}" ; }
magenta() { echo -en "${MAGENTA}$1${NC}" ; }
cyan() { echo -en "${CYAN}$1${NC}" ; }

function hr() {
    local char=${1:-=}
    local cols=${2:-$COLUMNS}
    if [ -z "$cols" ]; then
        cols=$(tput cols)
    fi
    printf "%${cols}s" | tr ' ' "$char"
}

function check_dependencies_are_installed() {
    local any_not_installed=0
    echo "Checking dependencies..."

    # for dependency in "${dependencies[@]}"; do
    for dependency in "$@"; do
        if command -v "$dependency" &> /dev/null; then
            echo -e "${GREEN}${dependency}${NC}\tis installed"
        else
            echo -e "${RED}${dependency}${NC}\tis not installed"
            any_not_installed=1
        fi
        sleep 0.1
    done

    if [ $any_not_installed -eq 1 ]; then
        red "Please install the missing dependencies and try again\n"
        return 1
    else
        green "All dependencies are installed\n"
    fi

    return 0
}
