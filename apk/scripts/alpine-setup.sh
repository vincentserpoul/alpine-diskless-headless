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

#==============================================================================#
#==================================== M A I N =================================#
#==============================================================================#

alpine-setup-prepare() {
    local -r ROOTFS_DIR=$1
    local -r LOCAL_CONFIG_DIR=$2

    # copy the setup scripts inside the rootfs
    mkdir -p "$ROOTFS_DIR"/install-scripts
    cp -a "$BUILD_DIR"/scripts/chroot/* "$ROOTFS_DIR"/install-scripts/

    # copy the config inside the rootfs
    mkdir -p "$ROOTFS_DIR"/config
    cp -a "$LOCAL_CONFIG_DIR"/* "$ROOTFS_DIR"/config/

}

alpine-setup-backup() {
    local -r ROOTFS_DIR=$1
    local -r TARGET_DIR=$2

    mv "$ROOTFS_DIR"/target/alpine.apkovl.tar.gz "$TARGET_DIR"/
    mv "$ROOTFS_DIR"/target/alpine.apkcache.tar.gz "$TARGET_DIR"/
}
