#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_ALPINE="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_ALPINE" ]]; then DIR_ALPINE="$PWD"; fi

. """$DIR_ALPINE""/helpers.sh"
. """$DIR_ALPINE""/../../scripts/utils.sh"
. """$DIR_ALPINE""/../../scripts/helpers.sh"

#============================== d o w n l o a d ===============================#

alpine-download() {
    local -r ARCH=$1
    local -r ALPINE_MIRROR=$2
    local -r ALPINE_BRANCH=$3
    local -r ALPINE_VERSION=$4

    local -r LIST_URL="$ALPINE_MIRROR"/"$ALPINE_BRANCH"/releases/"$ARCH"

    local -r FILE_DIR="""$DIR_ALPINE""/../downloads"

    local -r FILE_NAME="$(helpers-download-tar-name-get """$ARCH""" """$ALPINE_VERSION""")"
    local -r FILE_PATH="$(helpers-download-filepath-get "$ARCH" "$ALPINE_VERSION")"

    einfo "dowloading rpi alpine ""$ALPINE_VERSION"" for ""$ARCH"""

    if [ ! -f "$FILE_PATH" ]; then
        mkdir -p "$FILE_DIR"
        wget "$LIST_URL"/"$FILE_NAME" -O "$FILE_PATH"
    fi
}

#============================== e x t r a c t =================================#

alpine-extract() {
    local -r ARCH=$1
    local -r ALPINE_VERSION=$2

    local -r FILE_PATH="$(helpers-download-filepath-get "$ARCH" "$ALPINE_VERSION")"

    einfo "extracting rpi alpine ""$ALPINE_VERSION"" for ""$ARCH"""

    local -r WORK_DIR="$(helpers-workdir-name-get """$ARCH""" """$ALPINE_VERSION""")"
    mkdir -p "$WORK_DIR"

    echo "$FILE_PATH"

    tar xzf "$FILE_PATH" -C "$WORK_DIR"
}
