#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_PREDL="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_PREDL" ]]; then DIR_PREDL="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_PREDL""/../scripts/utils.sh"
# shellcheck source=/dev/null
. """$DIR_PREDL""/scripts/apk-tools.sh"

mkdir -p "$DIR_PREDL/downloads"
apk-tools-download "aarch64" "http://dl-cdn.alpinelinux.org/alpine" "latest-stable" "$DIR_PREDL/downloads"
apk-tools-download "armhf" "http://dl-cdn.alpinelinux.org/alpine" "latest-stable" "$DIR_PREDL/downloads"