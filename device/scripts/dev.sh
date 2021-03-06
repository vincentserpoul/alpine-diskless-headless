#!/usr/bin/env bash

set -Eeuo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_DEVICE=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
if [[ ! -d "$DIR_DEVICE" ]]; then DIR_DEVICE="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_DEVICE""/../../scripts/utils.sh"

#=============================== s d c a r d ==================================#

dev-partition-full() {
    local -r DEVICE_NAME=$1

    parted -a optimal -s "$DEVICE_NAME" \
        mklabel msdos \
        mkpart primary fat32 0% 256MiB \
        mkpart primary ext4 256MiB 100% \
        set 1 boot on
    # added for slow workstations
    sleep 1s
    mkfs.vfat -F 32 "$DEVICE_NAME"1 &&
        mkfs.ext4 -F "$DEVICE_NAME"2
}

dev-boot-mount() {
    local DEVICE_NAME=$1

    einfo "mounting boot partition ""$DEVICE_NAME""1"

    local -r MOUNTING_POINT="$DIR_DEVICE"/../mnt/boot

    mkdir -p "$MOUNTING_POINT"
    mount --make-private "$DEVICE_NAME"1 "$MOUNTING_POINT" || true

    echo "$MOUNTING_POINT"
}

dev-boot-umount() {
    local DEVICE_NAME=$1

    einfo "unmounting boot partition ""$DEVICE_NAME""1"

    umount "$DEVICE_NAME"1 --lazy || true
}

dev-disk-mount() {
    local DEVICE_NAME=$1

    einfo "mounting disk partition ""$DEVICE_NAME""2"

    local -r MOUNTING_POINT="$DIR_DEVICE"/../mnt/disk

    mkdir -p "$MOUNTING_POINT"
    mount --make-private "$DEVICE_NAME"2 "$MOUNTING_POINT" || true

    echo "$MOUNTING_POINT"
}

dev-disk-umount() {
    local DEVICE_NAME=$1

    einfo "unmounting disk partition ""$DEVICE_NAME""2"

    umount "$DEVICE_NAME"2 --lazy || true
}

dep-check parted
