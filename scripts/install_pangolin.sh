#!/usr/bin/env bash

set -e
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
THIRD_PARTY_DIR="$PROJECT_DIR/3rdparty"

source "$SCRIPT_DIR/utils.sh"

check_dependencies cmake g++ ninja git || exit 1

cd "$THIRD_PARTY_DIR" || exit 1

if [ -d "Pangolin" ]; then
    green "Pangolin already installed\n"
else
	green "Installing Pangolin...\n"
	# Use our fork of Pangolin
	git clone --recursive --progress https://github.com/Multi-Agent-Robotics/Pangolin.git
	.Pangolin/scripts/install_prerequisites.sh recommended
fi

pushd Pangolin || exit 1

# CMAKE_INSTALL_PREFIX="$HOME/.local"
CMAKE_INSTALL_PREFIX="$THIRD_PARTY_DIR/install"
if ! [ -d "$CMAKE_INSTALL_PREFIX" ]; then
    mkdir -p "$CMAKE_INSTALL_PREFIX"
    green "Creating install directory: $CMAKE_INSTALL_PREFIX"
fi
echo "CMAKE_INSTALL_PREFIX: $CMAKE_INSTALL_PREFIX"
cmake -S . -B ./build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$CMAKE_INSTALL_PREFIX"
cmake --build ./build --config Release

green "Installing Pangolin to $CMAKE_INSTALL_PREFIX\n" 
cmake --build ./build --target install --config Release
green "Installing Pangolin DONE\n"
