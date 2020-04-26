#!/usr/bin/env bash
#---help---
# Usage: ./run.sh [options]
#
# The goal of this script is to create a diskless, headless install of alpine
# linux for your SBC (rpi, rockpro64...), directly from your x86 computer.
#
# Just insert a sdcard and run it with the right parameters.
#
# It has a few dependencies: qemu, chroot, parted.
#
# Example:
#   sudo sudo ./run.sh -n myalpine -f
#
# Options and environment variables:
#
#   -d HARDWARE            which SMB you are targeting.
#                          Options: rpi
#                          Default: rpi
#
#   -a ARCH                CPU architecture for the SMB.
#                          Options: x86_64, x86, aarch64, armhf, armv7, ppc64le, s390x.
#                          Default: aarch64
#
#   -m ALPINE_MIRROR...    URI of the Aports mirror to fetch packages from.
#                          Default: http://dl-cdn.alpinelinux.org/alpine
#
#   -b ALPINE_BRANCH       Alpine branch to install.
#                          Default: latest-stable
#
#   -v ALPINE_VERSION      Alpine version to install.
#                          Default: 3.11.6
#
#   -p DEVICE_NAME         Name of the device to write to.
#                          Default: /dev/sda
#
#   -n BUILD_HOSTNAME      Hostname. Must be filled
#                          No default
#
#   -t TIMEZONE            Timezone.
#                          Default: Asia/Singapore
#
#   -f FORCE               If true, don't ask before writing to the device.
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

readonly VERSION="1.0.0"

#============================== i n c l u d e s ===============================#

DIR_BASE="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_BASE" ]]; then DIR_BASE="$PWD"; fi

. """$DIR_BASE""/scripts/utils.sh"

. """$DIR_BASE""/scripts/helpers.sh"
. """$DIR_BASE""/scripts/dev.sh"

#================================= m a i n ====================================#

while getopts 'd:a:m:b:v:p:n:t:fh' OPTION; do
    case "$OPTION" in
    d) HARDWARE="$OPTARG" ;;
    a) ARCH="$OPTARG" ;;
    m) ALPINE_MIRROR="$OPTARG" ;;
    b) ALPINE_BRANCH="$OPTARG" ;;
    v) ALPINE_VERSION="$OPTARG" ;;
    p) DEVICE_NAME="$OPTARG" ;;
    n) BUILD_HOSTNAME="$OPTARG" ;;
    t) TIMEZONE="$OPTARG" ;;
    f) FORCE=true ;;
    h)
        printf "alpine-diskless-headless-run v%s\n\n" "$VERSION"
        usage
        exit 0
        ;;
    *)
        echo "unknown flag"
        exit 0
        ;;
    esac
done

root-check
helpers-build-hostname-check

# Set default values
. """$DIR_BASE""/scripts/defaults.sh"

einfo "running alpine-diskless-headless-run"

# apk
"$DIR_BASE"/apk/build.sh \
    -a "$ARCH" \
    -m "$ALPINE_MIRROR" \
    -b "$ALPINE_BRANCH" \
    -v "$ALPINE_VERSION" \
    -n "$BUILD_HOSTNAME" \
    -t "$TIMEZONE"

# hardware boot
"$DIR_BASE"/"$HARDWARE"/build.sh \
    -a "$ARCH" \
    -m "$ALPINE_MIRROR" \
    -b "$ALPINE_BRANCH" \
    -v "$ALPINE_VERSION"

# /dev/sda partition, mount, copy files, umount
if [ "$FORCE" == false ]; then
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
tar xzf "$(helpers-hardware-filepath-get "$HARDWARE" "$ARCH" "$ALPINE_VERSION")" --no-same-owner -C "$BOOT_MOUNT_POINT"
cp "$(helpers-apkovl-filepath-get "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME")" "$BOOT_MOUNT_POINT"
dev-boot-umount "$DEVICE_NAME"

readonly DISK_MOUNT_POINT="$(dev-disk-mount "$DEVICE_NAME")"
einfo "extracting apk cache to main ext4 partition"
mkdir -p "$DISK_MOUNT_POINT"/var/cache/apk
tar xzf "$(helpers-apkcache-filepath-get "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME")" -C "$DISK_MOUNT_POINT"/var/cache/apk
dev-disk-umount "$DEVICE_NAME"
