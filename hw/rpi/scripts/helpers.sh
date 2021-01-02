#!/usr/bin/env bash

set -Eeuo pipefail

#==============================================================================#

DIR_RPI_HELPERS=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
if [[ ! -d "$DIR_RPI_HELPERS" ]]; then DIR_RPI_HELPERS="$PWD"; fi

#==============================================================================#

helpers-download-tar-name-get() {
    local -r ARCH=$1
    local -r ALPINE_VERSION=$2

    echo "alpine-rpi-""$ALPINE_VERSION""-""$ARCH"".tar.gz"
}

helpers-workdir-name-get() {
    local -r ARCH=$1
    local -r ALPINE_VERSION=$2

    echo "$DIR_RPI_HELPERS"/../work/"$ARCH"-"$ALPINE_VERSION"
}

helpers-download-filepath-get() {
    local -r ARCH=$1
    local -r ALPINE_VERSION=$2

    echo "$DIR_RPI_HELPERS"/../downloads/"$(helpers-download-tar-name-get "$ARCH" "$ALPINE_VERSION")"
}
