#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

readonly VERSION="1.0.0"

#============================== i n c l u d e s ===============================#

BUILD_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$BUILD_DIR" ]]; then BUILD_DIR="$PWD"; fi

# shellcheck source=/dev/null
. """$BUILD_DIR""/../scripts/utils.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/../scripts/helpers.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/secrets.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/apk-tools.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/alpine-setup.sh"

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#
while getopts 'a:b:v:m:n:t:w:h' OPTION; do
    case "$OPTION" in
    a) ARCH="$OPTARG" ;;
    m) ALPINE_MIRROR="$OPTARG" ;;
    b) ALPINE_BRANCH="$OPTARG" ;;
    v) ALPINE_VERSION="$OPTARG" ;;
    n) BUILD_HOSTNAME="$OPTARG" ;;
    t) TIMEZONE="$OPTARG" ;;
    w) NETWORKING="$OPTARG" ;;
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
dep-check chroot
# We should check only for the targeted arch, but if the user has qemu-aarch64-static, he probably has the others
dep-check qemu-aarch64-static

helpers-build-hostname-check

# Set default values
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/defaults.sh"

einfo "creating the local backup file (apkovl)"

# secrets
secrets

# rootfs dir
readonly ROOTFS_DIRECTORY="""$BUILD_DIR""/rootfs"
apk-tools-umount-rootfs-dir-all "$ROOTFS_DIRECTORY"
rm -rf "$ROOTFS_DIRECTORY"
mkdir "$ROOTFS_DIRECTORY"

apk-tools-downloadx "$ALPINE_MIRROR" "$ALPINE_BRANCH" "$BUILD_DIR/downloads"

apk-tools-mount-rootfs-dir-all "$ROOTFS_DIRECTORY"

apk-tools-install "$ROOTFS_DIRECTORY" "$ARCH" "$ALPINE_MIRROR" "$ALPINE_BRANCH"

alpine-prepare "$ROOTFS_DIRECTORY" "$ARCH" "$BUILD_HOSTNAME" "$ALPINE_VERSION"

#================================  a l p i n e  ===============================#

DNS="1.1.1.1"
KEYMAP="us us"
ROOT_PASSWORD=$(get_secret users root.password) \
REMOTE_USER="maintenance" \
REMOTE_USER_PASSWORD=$(get_secret users "$REMOTE_USER".password)
AUTHORIZED_KEYS=$(get_secret ssh authorized_keys)

chroot "$ROOTFS_DIRECTORY" /bin/sh -c \
    " \
    BUILD_HOSTNAME=\"$BUILD_HOSTNAME\" \
    ALPINE_MIRROR=\"$ALPINE_MIRROR\" \
    ALPINE_BRANCH=\"$ALPINE_BRANCH\" \
    TIMEZONE=\"$TIMEZONE\" \
    DNS=\"$DNS\" \
    KEYMAP=\"$KEYMAP\" \
    ROOT_PASSWORD=\"$ROOT_PASSWORD\" \
    REMOTE_USER=\"$REMOTE_USER\" \
    REMOTE_USER_PASSWORD=\"$REMOTE_USER_PASSWORD\" \
    AUTHORIZED_KEYS=\"$AUTHORIZED_KEYS\" \
    /chroot/base.sh \
    "

# run desired provisioners
chroot "$ROOTFS_DIRECTORY" /bin/sh -c "REMOTE_USER=$REMOTE_USER /chroot/provisioners/twofa.sh"

# Check ../../../scripts/defaults for the different values
if test "$NETWORKING" = "$ETHERNET_ONLY" || test "$NETWORKING" = "$ALL"; then
    chroot "$ROOTFS_DIRECTORY" /bin/sh -c "BUILD_HOSTNAME=\"$BUILD_HOSTNAME\" /chroot/provisioners/ethernet.sh"
fi
if test "$NETWORKING" = "$WLAN_ONLY" || test "$NETWORKING" = "$ALL"; then
    WLAN_SSID=$(get_secret wlan ssid)
    WLAN_PASSWORD=$(get_secret wlan password)
    chroot "$ROOTFS_DIRECTORY" /bin/sh -c "BUILD_HOSTNAME=\"$BUILD_HOSTNAME\" WLAN_SSID=\"$WLAN_SSID\" WLAN_PASSWORD=\"$WLAN_PASSWORD\" /chroot/provisioners/wlan.sh"
fi

chroot "$ROOTFS_DIRECTORY" /chroot/cache-lbu.sh

#================================  a l p i n e  ===============================#

alpine-teardown "$ROOTFS_DIRECTORY" "$ARCH" "$BUILD_HOSTNAME" "$ALPINE_VERSION"

apk-tools-umount-rootfs-dir-all "$ROOTFS_DIRECTORY"

rm -rf "$ROOTFS_DIRECTORY"
