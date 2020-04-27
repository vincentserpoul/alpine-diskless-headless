#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_ALPINE_SETUP="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_ALPINE_SETUP" ]]; then DIR_ALPINE_SETUP="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_ALPINE_SETUP""/../../scripts/utils.sh"
# shellcheck source=/dev/null
. """$DIR_ALPINE_SETUP""/../../scripts/helpers.sh"

#============================= a p k  c a c h e ===============================#

alpine-setup-apkcache-save() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r ALPINE_VERSION=$3
    local -r BUILD_HOSTNAME=$4

    einfo "backing up apk cache outside of rootfs"

    mkdir -p "$DIR_ALPINE_SETUP"/../apkovl

    tar czf \
        "$(helpers-apkcache-filepath-get "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME")" \
        -C "$ROOTFS_DIR"/var/cache/apk \
        .
}

#=================================== l b u ====================================#

alpine-setup-apkovl-save() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r ALPINE_VERSION=$3
    local -r BUILD_HOSTNAME=$4

    einfo "backing up apkovl outside of rootfs"

    mkdir -p "$DIR_ALPINE_SETUP"/../apkovl
    mv "$ROOTFS_DIR"/alpine.apkovl.tar.gz \
        "$(helpers-apkovl-filepath-get "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME")"
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
    local -r ALPINE_VERSION=$6
    local -r TIMEZONE=$7
    local -r NETWORKING=$8

    cp "$BUILD_DIR"/scripts/alpine-setup-local.sh "$ROOTFS_DIRECTORY"/
    cp -r "$BUILD_DIR"/secrets "$ROOTFS_DIRECTORY"/

    chroot "$ROOTFS_DIRECTORY" \
        /alpine-setup-local.sh "$BUILD_HOSTNAME" "$ALPINE_MIRROR" "$ALPINE_BRANCH" "$TIMEZONE" "$NETWORKING"

    # IMPORTANT CLEANUP - DO NOT ERASE EVEN THOUGH NOT IN THE LCCAL BACKUP
    rm "$ROOTFS_DIRECTORY"/alpine-setup-local.sh
    rm -rf "$ROOTFS_DIRECTORY"/secrets

    alpine-setup-apkcache-save "$ROOTFS_DIR" "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME"
    alpine-setup-apkovl-save "$ROOTFS_DIR" "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME"
}
