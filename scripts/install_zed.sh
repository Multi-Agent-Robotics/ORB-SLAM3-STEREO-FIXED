#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/utils.sh" || exit 1

pushd "$SCRIPT_DIR" || exit 1
wget --header="Host: stereolabs.sfo2.cdn.digitaloceanspaces.com" --header="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36" --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8" --header="Accept-Language: en-GB,en-US;q=0.9,en;q=0.8,da;q=0.7" --header="Referer: https://www.stereolabs.com/" "https://stereolabs.sfo2.cdn.digitaloceanspaces.com/zedsdk/3.8/ZED_SDK_Ubuntu20_cuda11.7_v3.8.2.zstd.run" -c -O 'ZED_SDK_Ubuntu20_cuda11.7_v3.8.2.zstd.run'

chmod +x ZED_SDK_Ubuntu20_cuda11.7_v3.8.2.zstd.run
./ZED_SDK_Ubuntu20_cuda11.7_v3.8.2.zstd.run
