#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

readonly VERSION="0.1.0"

#============================== i n c l u d e s ===============================#

BUILD_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$BUILD_DIR" ]]; then BUILD_DIR="$PWD"; fi

. """$BUILD_DIR""/../scripts/utils.sh"
. """$BUILD_DIR""/../scripts/helpers.sh"
. """$BUILD_DIR""/scripts/secrets.sh"
. """$BUILD_DIR""/scripts/apk-tools.sh"
. """$BUILD_DIR""/scripts/alpine-setup.sh"

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#
while getopts 'a:b:v:m:n:t:h' OPTION; do
    case "$OPTION" in
    a) ARCH="$OPTARG" ;;
    m) ALPINE_MIRROR="$OPTARG" ;;
    b) ALPINE_BRANCH="$OPTARG" ;;
    v) ALPINE_VERSION="$OPTARG" ;;
    n) BUILD_HOSTNAME="$OPTARG" ;;
    t) TIMEZONE="$OPTARG" ;;
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

#===================================  M a i n  ================================#

root-check
helpers-build-hostname-check

# Set default values
. """$BUILD_DIR""/../scripts/defaults.sh"

# Check if build hostname is empty
if [ -z "$BUILD_HOSTNAME" ]; then
    die "you need to give a hostname as an argument: -n HOSTNAME"
fi

einfo "creating the local backup file (apkovl)"

secrets

# rootfs dir
readonly ROOTFS_DIRECTORY="""$BUILD_DIR""/rootfs"
apk-tools-umount-rootfs-dir-all "$ROOTFS_DIRECTORY"
rm -rf "$ROOTFS_DIRECTORY"
mkdir "$ROOTFS_DIRECTORY"

apk-tools-downloadx "$ALPINE_MIRROR" "$ALPINE_BRANCH"

apk-tools-mount-rootfs-dir-all "$ROOTFS_DIRECTORY"

apk-tools-install "$ROOTFS_DIRECTORY" "$ARCH" "$ALPINE_MIRROR" "$ALPINE_BRANCH"

alpine-setup "$ROOTFS_DIRECTORY" "$ARCH" "$BUILD_HOSTNAME" "$ALPINE_MIRROR" "$ALPINE_BRANCH" "$ALPINE_VERSION" "$TIMEZONE"

apk-tools-umount-rootfs-dir-all "$ROOTFS_DIRECTORY"

rm -rf "$ROOTFS_DIRECTORY"
