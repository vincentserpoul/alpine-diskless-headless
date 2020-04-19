#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_ALPINE="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_ALPINE" ]]; then DIR_ALPINE="$PWD"; fi

. """$DIR_ALPINE""/../../scripts/utils.sh"
. """$DIR_ALPINE""/../../scripts/helpers.sh"

#============================== i n c l u d e s ===============================#

alpine-download-tar-name-get() {
    local -r ARCH=$1
    local -r ALPINE_VERSION=$2

    echo "alpine-rpi-""$ALPINE_VERSION""-""$ARCH"".tar.gz"
}

alpine-download() {
    local -r ARCH=$1
    local -r ALPINE_MIRROR=$2
    local -r ALPINE_BRANCH=$3
    local -r ALPINE_VERSION=$4

    local -r LIST_URL="$ALPINE_MIRROR"/"$ALPINE_BRANCH"/releases/"$ARCH"

    local -r FILE_DIR="""$DIR_ALPINE""/../boot"

    local -r FILE_NAME="$(alpine-download-tar-name-get """$ARCH""" """$ALPINE_VERSION""")"

    local -r FILE_PATH="$(helpers-hardware-filepath-get rpi "$ARCH" "$ALPINE_VERSION")"

    einfo "dowloading rpi alpine ""$ALPINE_VERSION"" for ""$ARCH"""

    if [ ! -f "$FILE_PATH" ]; then
        mkdir -p "$FILE_DIR"
        wget "$LIST_URL"/"$FILE_NAME" -O "$FILE_PATH"
    fi
}
