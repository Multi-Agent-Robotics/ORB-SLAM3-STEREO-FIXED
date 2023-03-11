#!/usr/bin/env bash

# Install OpenCV 4.2.0 on Ubuntu 20.04

set -e
set -o pipefail

function pushd() { command pushd "$@" > /dev/null; }
function popd() { command popd > /dev/null; }

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

declare -a dependencies=(cmake g++ wget unzip ninja)

fail=0

echo "Checking dependencies..."

for dependency in "${dependencies[@]}"; do
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
    echo "Please install the dependencies and try again"
    exit 1
fi

hr -

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ -z "$1" ]; then
    DOWNLOAD_DIR="$SCRIPT_DIR/../Thirdparty"
else
    DOWNLOAD_DIR="$1"
fi

mkdir -p "$DOWNLOAD_DIR"
pushd "$DOWNLOAD_DIR"

if [ -d opencv-4.2.0 ]; then
    green "OpenCV 4.2.0 already downloaded\n"
else
    echo "Downloading OpenCV 4.2.0 and unpacking..."
    set +x
    wget -O opencv.zip https://github.com/opencv/opencv/archive/4.2.0.zip
    unzip -q opencv.zip
    rm opencv.zip
    set -x
    echo "Downloaded OpenCV 4.2.0 to $DOWNLOAD_DIR"
fi

popd

hr -


# Build OpenCV 4.2.0
pushd "$DOWNLOAD_DIR/opencv-4.2.0"
pwd
echo "Building OpenCV 4.2.0..."

CMAKE_INSTALL_PREFIX="$HOME/.local"
cmake -S . -B ./build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$CMAKE_INSTALL_PREFIX"
cmake --build ./build --config Release
echo "Installing OpenCV 4.2.0... to $CMAKE_INSTALL_PREFIX" 
cmake --build ./build --target install --config Release

echo "Building OpenCV 4.2.0 done"
