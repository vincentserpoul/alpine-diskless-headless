#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup_device_run SIGINT SIGTERM ERR EXIT

#==============================================================================#

readonly VERSION="0.1.4"

#============================== i n c l u d e s ===============================#

RUN_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
if [[ ! -d "$RUN_DIR" ]]; then RUN_DIR="$PWD"; fi

# shellcheck source=/dev/null
. """$RUN_DIR""/../scripts/utils.sh"
# shellcheck source=/dev/null
. """$RUN_DIR""/scripts/dev.sh"

#========================= u s a g e  &  c l e a n u p ========================#

usage() {
    echo "alpine-diskless-headless-device-run ""$VERSION"""
    echo

    cat <<EOF
Usage: ./run.sh [options]

The goal of this script is to burn apkovl, boot and cache to a device

Just insert a sdcard and run it with the right parameters.

Example:
  sudo ./run.sh -s "$(pwd)"/example/pleine-lune-rpi3b+/target -d /dev/sda -f

Options and environment variables:

  -s SOURCE_DIR               source directory containing boot, cache and apkovl
                              Default: source dir

  -d DEVICE_NAME              name of the device to write to. for example /dev/sda
                              Default: empty

  -f FORCE_DEV_WRITE          if true, don't ask before writing to the device.
                              Default: false

  -h                          show this help message and exit.

Each option can be also provided by environment variable. If both option and
variable is specified and the option accepts only one argument, then the
option takes precedence.

https://github.com/vincentserpoul/alpine-diskless-headless
EOF
    exit
}

cleanup_device_run() {
    trap - SIGINT SIGTERM ERR EXIT
    einfo "nothing to clean for device/run.sh"
}

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

#===================================  M e n u  ================================#

parse_params() {
    SOURCE_DIR=''
    DEVICE_NAME=''
    FORCE_DEV_WRITE=false

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        -s | --source-dir)
            SOURCE_DIR="${2-}"
            shift
            ;;
        -d | --device-name)
            DEVICE_NAME="${2-}"
            shift
            ;;
        -f | --force-dev-write) FORCE_DEV_WRITE=true ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    # args=("$@")

    # check required params and arguments
    [[ -z "${SOURCE_DIR+x}" ]] && die "Missing required parameter: -s source directory containing boot, cache and apkovl"
    [[ -z "${DEVICE_NAME+x}" ]] && die "Missing required parameter: -d device name, like /dev/sda"

    # [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

    return 0
}

parse_params "$@"

#=============================  s o u r c e  d i r  ===========================#

einfo "checking source dir"

if [[ ! -d "$SOURCE_DIR" ]]; then
    die "$SOURCE_DIR is not a dir"
fi

#=============================  d e v i c e  n a m e  =========================#

einfo "checking device name"

if [[ ! -b "$DEVICE_NAME" ]]; then
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
