#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_HELPERS="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_HELPERS" ]]; then DIR_HELPERS="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_HELPERS""/utils.sh"

#==============================================================================#

helpers-build-hostname-check() {
    # Check if build hostname is empty
    if [ -z "$BUILD_HOSTNAME" ]; then
        die "you need to give a hostname as an argument: -n HOSTNAME"
    fi
}

helpers-hardware-filepath-get() {
    local -r HARDWARE=$1
    local -r ARCH=$2
    local -r ALPINE_VERSION=$3
    echo "$DIR_HELPERS"/../"$HARDWARE"/boot/alpine-"$ALPINE_VERSION"-"$ARCH".tar.gz
}

helpers-apkovl-filepath-get() {
    local -r ARCH=$1
    local -r ALPINE_VERSION=$2
    local -r BUILD_HOSTNAME=$3

    echo "$DIR_HELPERS"/../apk/apkovl/alpine-"$ALPINE_VERSION"-"$ARCH"-"$BUILD_HOSTNAME".apkovl.tar.gz
}

helpers-apkcache-filepath-get() {
    local -r ARCH=$1
    local -r ALPINE_VERSION=$2
    local -r BUILD_HOSTNAME=$3

    echo "$DIR_HELPERS"/../apk/apkovl/alpine-"$ALPINE_VERSION"-"$ARCH"-"$BUILD_HOSTNAME".apkcache.tar.gz
}
