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
    exit 0
fi

green "Installing Pangolin...\n"
# Use our fork of Pangolin
git clone --recursive --progress https://github.com/Multi-Agent-Robotics/Pangolin.git
pushd Pangolin || exit 1
./scripts/install_prerequisites.sh recommended

CMAKE_INSTALL_PREFIX="$HOME/.local"
cmake -S . -B ./build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$CMAKE_INSTALL_PREFIX"
cmake --build ./build --config Release

green "Installing Pangolin to $CMAKE_INSTALL_PREFIX\n" 
cmake --build ./build --target install --config Release
green "Installing Pangolin 4.2.0 DONE\n"