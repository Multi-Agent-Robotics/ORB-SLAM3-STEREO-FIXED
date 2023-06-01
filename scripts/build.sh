#!/usr/bin/env bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# "${SCRIPT_DIR}"/install_pangolin.sh

source "$SCRIPT_DIR/utils.sh" || exit 1

PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
THIRD_PARTY_DIR="$PROJECT_DIR/3rdparty"

echo -e "${YELLOW}SCRIPT_DIR${NC}:      $SCRIPT_DIR"
echo -e "${YELLOW}PROJECT_DIR${NC}:     $PROJECT_DIR"
echo -e "${YELLOW}THIRD_PARTY_DIR${NC}: $THIRD_PARTY_DIR"

if ! [ -d "$THIRD_PARTY_DIR" ]; then
	red "${THIRD_PARTY_DIR} directory not found\n"
	exit 1
fi

printf "%s" "${CYAN}"
test -f "$SCRIPT_DIR/orbslam3_ascii_logo.txt" && cat "$SCRIPT_DIR/orbslam3_ascii_logo.txt"
printf "%s" "${NC}"

hr -

if ! check_dependencies_are_installed cmake g++ ninja tar; then
    exit 1
fi

hr -

echo "Uncompressing vocabulary ..."
pushd vocabulary || exit 1
if [ ! -f ORBvoc.txt ]; then
	tar -xf ORBvoc.txt.tar.gz
	green "Uncompressing vocabulary done\n"
else
	green "Vocabulary already uncompressed\n"
fi
popd

hr -

green "Configuring orbslam3 ...\n"
CMAKE_INSTALL_PREFIX="$THIRD_PARTY_DIR"/install
mkdir -p "$CMAKE_INSTALL_PREFIX"
cmake -S . -B ./build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$CMAKE_INSTALL_PREFIX"
green "Configuring orbslam3 DONE\n"

green "Building orbslam3 ...\n"
cmake --build ./build
green "Building orbslam3 DONE\n"

green "Installing orbslam3 ...\n"
cmake --build build --target install
green "Installing orbslam3 DONE\n"

green "All done :D\n"

exit 0
