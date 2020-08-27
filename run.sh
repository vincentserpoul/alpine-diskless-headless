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
#   -c CONFIG_FILE_PATH    path of the config.env file
#
#   -d DEVICE_NAME         Name of the device to write to. for example /dev/sda
#                          Default: no default, must be filled
#
#   -r HARDWARE            which SMB you are targeting.
#                          Options: rpi
#                          Default: rpi
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

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

while getopts 'c:a:t:w:d:fh' OPTION; do
    case "$OPTION" in
    c) CONFIG_FILE_PATH="$OPTARG" ;;
    a) ADDITIONAL_PROVISIONERS="$OPTARG" ;;
    t) TARGET_DIR="$OPTARG" ;;
    w) TARGET_HW="$OPTARG" ;;
    d) DEVICE_NAME="$OPTARG" ;;
    f) FORCE_DEV_WRITE=true ;;
    h)
        echo "alpine-diskless-headless-run v""$VERSION"""
        exit 0
        ;;
    *)
        echo "unknown flag"
        exit 0
        ;;
    esac
done

#===================================  M a i n  ================================#

root-check

# Check if device name is filled
if [ -z "$DEVICE_NAME" ]; then
    die "you need to specify a device with -d option. for example: -d /dev/sda"
fi

einfo "running alpine-diskless-headless-run"

# apk
"$DIR_BASE"/apk/build.sh -c "$CONFIG_FILE_PATH" -a "$ADDITIONAL_PROVISIONERS" -t "$TARGET_DIR"

# if hardware not specified, we don't continue
if [[ -z ${TARGET_HW+x} ]]; then
    einfo "finished successfully!"
    exit 0
fi

# hardware boot
"$DIR_BASE"/hw/build.sh -c "$CONFIG_FILE_PATH" -t "$TARGET_DIR" -w "$TARGET_HW"

# if hardware not specified, we don't continue
if [[ -z ${DEVICE_NAME+x} ]]; then
    einfo "finished successfully!"
    exit 0
fi

"$DIR_BASE"/device/run.sh -s "$TARGET_DIR" -d "$DEVICE_NAME" -f "$FORCE_DEV_WRITE"

einfo "finished successfully!"
echo
ewarn "to connect to your SBC, just put the sdcard in it, wait for it to boot and run:"
ewarn "ssh -i <YOURSSHKEY> <REMOTE_USER>@<HOSTNAME>"
