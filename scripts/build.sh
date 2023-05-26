#!/usr/bin/env bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source "$SCRIPT_DIR/utils.sh" || exit 1

PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
THIRD_PARTY_DIR="$PROJECT_DIR/3rdparty"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "PROJECT_DIR: $PROJECT_DIR"
echo "THIRD_PARTY_DIR: $THIRD_PARTY_DIR"

if ! [ -d "$THIRD_PARTY_DIR" ]; then
	red "${THIRD_PARTY_DIR} directory not found\n"
	exit 1
fi

declare -a dependencies=(cmake g++ ninja tar)

fail=0

hr -

green "Checking dependencies...\n"

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

green "Checking dependencies DONE\n"

if [ $fail -eq 1 ]; then
    red "Please install the dependencies and try again\n"
    exit 1
else
	green "All dependencies are installed\n"
fi

hr -

function build_3rdparty_library() {
	if [ -z "$1" ]; then
		red "No library name provided\n"
		exit 1
	fi

	green "Configuring and building ${THIRD_PARTY_DIR}/$1 ...\n"
	pushd "$THIRD_PARTY_DIR/$1" || exit 1

    CMAKE_INSTALL_PREFIX="$THIRD_PARTY_DIR/install"
    cmake -S . -B ./build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$CMAKE_INSTALL_PREFIX"
    cmake --build ./build --target install

	green "Configuring and building ${THIRD_PARTY_DIR}/$1 DONE\n"

	popd
	hr -
}

build_3rdparty_library "DBoW2"
build_3rdparty_library "g2o"
build_3rdparty_library "Sophus"

pushd vocabulary || exit 1
if [ ! -f ORBvoc.txt ]; then
	green "Uncompressing vocabulary ...\n"
	tar xf ORBvoc.txt.tar.gz
	green "Uncompressing vocabulary Done\n"
else
	green "Vocabulary already uncompressed\n"
fi
popd

hr -

green "Configuring and building ORB_SLAM3 ...\n"
cmake -S . -B ./build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build ./build
test -d ~/.local || mkdir -p ~/.local
CMAKE_INSTALL_PREFIX=~/.local cmake --build ./build --target install
green "Configuring and building ORB_SLAM3 DONE\n"

green "All done :D\n"

exit 0
