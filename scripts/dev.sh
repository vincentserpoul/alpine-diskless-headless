#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_DEVICE="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_DEVICE" ]]; then DIR_DEVICE="$PWD"; fi

. """$DIR_DEVICE""/utils.sh"

#=============================== s d c a r d ==================================#

dev-partition-full() {
    local -r DEVICE_NAME=$1

    parted -a optimal -s "$DEVICE_NAME" \
        mklabel msdos \
        mkpart primary fat32 0% 256MiB \
        mkpart primary ext4 256MiB 100% \
        set 1 boot on &&
        mkfs.vfat -F 32 "$DEVICE_NAME"1 &&
        mkfs.ext4 -F "$DEVICE_NAME"2
}

dev-partition() {
    local -r DEVICE_NAME=$1

    parted -a optimal -s "$DEVICE_NAME" \
        mklabel msdos \
        mkpart primary fat32 0% 256MiB \
        set 1 boot on &&
        mkfs.vfat -F 32 "$DEVICE_NAME"1
}

dev-mount() {
    local DEVICE_NAME=$1

    einfo "mounting partition ""$DEVICE_NAME""1"

    local -r MOUNTING_POINT="$DIR_DEVICE"/../mnt

    mkdir -p "$MOUNTING_POINT"
    mount --make-private "$DEVICE_NAME"1 "$MOUNTING_POINT" || true

    echo "$MOUNTING_POINT"
}

dev-umount() {
    local DEVICE_NAME=$1

    einfo "unmounting partition ""$DEVICE_NAME""1"

    umount "$DEVICE_NAME"1 --lazy || true
}

dep-check parted
