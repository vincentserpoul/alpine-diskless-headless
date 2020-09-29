#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

readonly VERSION=$(git describe --tags --abbrev=0)

#============================== i n c l u d e s ===============================#

RUN_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$RUN_DIR" ]]; then RUN_DIR="$PWD"; fi

# shellcheck source=/dev/null
. """$RUN_DIR""/../scripts/utils.sh"
# shellcheck source=/dev/null
. """$RUN_DIR""/scripts/dev.sh"

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

while getopts 's:d:fh' OPTION; do
    case "$OPTION" in
    s) SOURCE_DIR="$OPTARG" ;;
    d) DEVICE_NAME="$OPTARG" ;;
    f) FORCE_DEV_WRITE=true ;;
    h)
        echo "alpine-diskless-headless-dev-run ""$VERSION"""
        exit 0
        ;;
    *)
        echo "unknown flag"
        exit 0
        ;;
    esac
done

: "${FORCE_DEV_WRITE:=false}"

#=============================  s o u r c e  d i r  ===========================#

einfo "checking target dir"

if [[ -z ${SOURCE_DIR+x} ]]; then
    die "you need a source directory containing boot, cache and apkovl"
fi
if [[ ! -d "$SOURCE_DIR" ]]; then
    die "$SOURCE_DIR is not a dir"
fi

#=============================  d e v i c e  n a m e  =========================#

einfo "checking device name"

if [[ -z ${DEVICE_NAME+x} ]]; then
    die "you need a device name, like /dev/sda"
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    die "$DEVICE_NAME does not exist"
fi

#===================================  M a i n  ================================#

root-check

# /dev/sda partition, mount, copy files, umount
if [ "$FORCE_DEV_WRITE" == false ]; then
    echo
    read -p "Are you sure you want to format ""$DEVICE_NAME"" (Y/y)?" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        die "script stopped by user"
    fi
fi

dev-partition-full "$DEVICE_NAME"

readonly BOOT_MOUNT_POINT="$(dev-boot-mount "$DEVICE_NAME")"
einfo "copying boot files and local backup to boot partition"
tar xzf "$SOURCE_DIR"/alpine.boot.tar.gz --no-same-owner -C "$BOOT_MOUNT_POINT"
cp "$SOURCE_DIR"/alpine.apkovl.tar.gz "$BOOT_MOUNT_POINT"
dev-boot-umount "$DEVICE_NAME"

readonly DISK_MOUNT_POINT="$(dev-disk-mount "$DEVICE_NAME")"
einfo "extracting apk cache to main ext4 partition"
mkdir -p "$DISK_MOUNT_POINT"/var/cache/apk
tar xzf "$SOURCE_DIR"/alpine.apkcache.tar.gz -C "$DISK_MOUNT_POINT"/var/cache/apk
dev-disk-umount "$DEVICE_NAME"
