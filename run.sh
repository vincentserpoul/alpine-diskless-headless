#!/usr/bin/env bash
#---help---
# Usage: ./run.sh [options]
#
# The goal of this script is to create a diskless, headless install of alpine
# linux for your SBC (rpi, rockpro64...), directly from your x86 computer.
#
# Just insert a sdcard and run it with the right parameters.
#
# It has a few dependencies: qemu-user-static, chroot, parted.
#
# Example:
#   sudo sudo ./run.sh -d rpi -f
#
# Options and environment variables:
#
#   -r HARDWARE            which SMB you are targeting.
#                          Options: rpi
#                          Default: rpi
#
#   -d DEVICE_NAME         Name of the device to write to.
#                          Default: /dev/sda
#
#   -c CONFIG_FILE_PATH    path of the config.env file
#
#   -f FORCE_DEV_WRITE     If true, don't ask before writing to the device.
#                          Default: false
#
#   -h                     Show this help message and exit.
#
# Each option can be also provided by environment variable. If both option and
# variable is specified and the option accepts only one argument, then the
# option takes precedence.
#
# https://github.com/vincentserpoul/alpine-diskless-headless
#---help---

set -euo pipefail

#==============================================================================#

readonly VERSION="2.0.0"

#============================== i n c l u d e s ===============================#

DIR_BASE="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_BASE" ]]; then DIR_BASE="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_BASE""/scripts/utils.sh"
# shellcheck source=/dev/null
. """$DIR_BASE""/scripts/helpers.sh"
# shellcheck source=/dev/null
. """$DIR_BASE""/scripts/dev.sh"

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

while getopts 'r:d:c:fh' OPTION; do
    case "$OPTION" in
    r) HARDWARE="$OPTARG" ;;
    d) DEVICE_NAME="$OPTARG" ;;
    c) CONFIG_FILE_PATH="$OPTARG" ;;
    f) FORCE_DEV_WRITE=true ;;
    h)
        echo "alpine-diskless-headless-apk-build v""$VERSION"""
        exit 0
        ;;
    *)
        echo "unknown flag"
        exit 0
        ;;
    esac
done

# default vars
: "${HARDWARE:="rpi"}"
: "${DEVICE_NAME:="/dev/sda"}"
: "${FORCE_DEV_WRITE:=false}"

#================================  c o n f i g  ===============================#

einfo "checking config"

# check if config is present
if [[ -z ${CONFIG_FILE_PATH+x} ]]; then
    die "you need to supply a config path -c <CONFIG_FILE_PATH>"
fi
if [[ ! -f "$CONFIG_FILE_PATH" ]]; then
    die "the config path you supplied is not valid"
fi

# turn relative into absolute
CONFIG_FILE_PATH="$(cd "$(dirname "$CONFIG_FILE_PATH")" && pwd)/$(basename "$CONFIG_FILE_PATH")"

# Load the config
# shellcheck source=/dev/null
. "$CONFIG_FILE_PATH"

readonly CONFIG_DIR=$(dirname "$CONFIG_FILE_PATH")

# check if hostname is filled
helpers-base-hostname-check
#===================================  M a i n  ================================#

root-check

einfo "running alpine-diskless-headless-run"

# apk
"$DIR_BASE"/apk/build.sh -c "$CONFIG_FILE_PATH"

# hardware boot
"$DIR_BASE"/"$HARDWARE"/build.sh -c "$CONFIG_FILE_PATH"

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
tar xzf "$(helpers-hardware-filepath-get "$HARDWARE" "$BASE_ARCH" "$BASE_ALPINE_VERSION")" --no-same-owner -C "$BOOT_MOUNT_POINT"
cp "$CONFIG_DIR"/alpine.apkovl.tar.gz "$BOOT_MOUNT_POINT"
dev-boot-umount "$DEVICE_NAME"

readonly DISK_MOUNT_POINT="$(dev-disk-mount "$DEVICE_NAME")"
einfo "extracting apk cache to main ext4 partition"
mkdir -p "$DISK_MOUNT_POINT"/var/cache/apk
tar xzf "$CONFIG_DIR"/alpine.apkcache.tar.gz -C "$DISK_MOUNT_POINT"/var/cache/apk
dev-disk-umount "$DEVICE_NAME"

einfo "finished successfully!"
echo
ewarn "to connect to your SBC, just put the sdcard in it, wait for it to boot and run:"
ewarn "ssh -i ~/.ssh/id_ed25519_alpine_diskless maintenance@$BASE_HOSTNAME"
