#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_ALPINE_SETUP="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_ALPINE_SETUP" ]]; then DIR_ALPINE_SETUP="$PWD"; fi

. """$DIR_ALPINE_SETUP""/../../scripts/utils.sh"
. """$DIR_ALPINE_SETUP""/../../scripts/helpers.sh"

#=================================== l b u ====================================#

alpine-setup-apkovl-save() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r ALPINE_VERSION=$3
    local -r BUILD_HOSTNAME=$4

    einfo "backing up apkovl outside of rootfs"

    mkdir -p "$DIR_ALPINE_SETUP"/../apkovl

    mv "$ROOTFS_DIR"/alpine.apkovl.tar.gz "$(helpers-apkovl-filepath-get "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME")"
}

#==============================================================================#
#==================================== M A I N =================================#
#==============================================================================#

alpine-setup() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r BUILD_HOSTNAME=$3
    local -r ALPINE_MIRROR=$4
    local -r ALPINE_BRANCH=$5
    local -r TIMEZONE=$6
    local -r ALPINE_VERSION=$7

    cp "$BUILD_DIR"/scripts/alpine-setup-local.sh "$ROOTFS_DIRECTORY"/
    cp -r "$BUILD_DIR"/secrets "$ROOTFS_DIRECTORY"/

    chroot "$ROOTFS_DIRECTORY" /alpine-setup-local.sh "$BUILD_HOSTNAME" "$ALPINE_MIRROR" "$ALPINE_BRANCH" "$TIMEZONE"

    alpine-setup-apkovl-save "$ROOTFS_DIR" "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME"
}
