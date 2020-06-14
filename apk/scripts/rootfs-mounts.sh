#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_ROOTFS="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_ROOTFS" ]]; then DIR_ROOTFS="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_ROOTFS""/../../scripts/utils.sh"

#===============================  r o o t f s  ================================#

rootfs-mount-all() {
    local -r ROOTFS_DIR=$1

    einfo "mounting proc, sys, dev in ""$ROOTFS_DIR"""

    mkdir -p "$ROOTFS_DIR"/proc
    mkdir -p "$ROOTFS_DIR"/sys
    mkdir -p "$ROOTFS_DIR"/dev

    mount -v -t proc none "$ROOTFS_DIR"/proc/
    mount -v --rbind /sys "$ROOTFS_DIR"/sys/
    mount --make-rprivate "$ROOTFS_DIR"/sys/
    mount -v --rbind /dev "$ROOTFS_DIR"/dev/
    mount --make-rprivate "$ROOTFS_DIR"/dev/
}

rootfs-unmount-all() {
    local -r ROOTFS_DIR=$1

    einfo "unmounting proc, sys, dev from ""$ROOTFS_DIR"""

    umount "$ROOTFS_DIR"/dev --lazy >/dev/null 2>&1 || true
    umount "$ROOTFS_DIR"/proc --lazy >/dev/null 2>&1 || true
    umount "$ROOTFS_DIR"/sys --lazy >/dev/null 2>&1 || true

    rmdir "$ROOTFS_DIR"/proc >/dev/null 2>&1 || true
    rmdir "$ROOTFS_DIR"/sys >/dev/null 2>&1 || true
    rmdir "$ROOTFS_DIR"/dev >/dev/null 2>&1 || true

}
