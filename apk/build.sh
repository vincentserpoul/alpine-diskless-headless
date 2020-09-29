#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

readonly VERSION=$(git describe --tags --abbrev=0)

#============================== i n c l u d e s ===============================#

BUILD_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$BUILD_DIR" ]]; then BUILD_DIR="$PWD"; fi

# shellcheck source=/dev/null
. """$BUILD_DIR""/../scripts/utils.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/../scripts/helpers.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/rootfs-mounts.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/apk-tools.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/alpine-setup.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/additional-provisioners.sh"

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

while getopts 'c:a:t:h' OPTION; do
    case "$OPTION" in
    c) CONFIG_FILE_PATH="$OPTARG" ;;
    a) ADDITIONAL_PROVISIONERS="$OPTARG" ;;
    t) TARGET_DIR="$OPTARG" ;;
    h)
        echo "alpine-diskless-headless-apk-build ""$VERSION"""
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

#==============================  d e p  c h e c k  ============================#

einfo "checking dependencies"

dep-check chroot
# We should check only for the targeted arch, but if the user has qemu-aarch64-static, he probably has the others
dep-check qemu-aarch64-static

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

#=============================  t a r g e t  d i r  ===========================#

einfo "checking target dir"

if [[ -z ${TARGET_DIR+x} ]]; then
    TARGET_DIR="$CONFIG_DIR"
fi
if [[ ! -d "$TARGET_DIR" ]]; then
    die "$TARGET_DIR is not a dir"
fi

#===============================  r o o t f s   ===============================#

einfo "preparing rootfs"

# rootfs dir
if [[ -z ${ROOTFS_DIRECTORY+x} ]]; then
    ROOTFS_DIRECTORY="""$BUILD_DIR""/rootfs"
fi
rootfs-unmount-all "$ROOTFS_DIRECTORY"
rm -rf "$ROOTFS_DIRECTORY"
mkdir -p "$ROOTFS_DIRECTORY"

#===============================  a p k o v l   ===============================#

einfo "extracting and installing apk tools"

apk-tools-download "$BASE_ARCH" "$BASE_ALPINE_MIRROR" "$BASE_ALPINE_BRANCH" "$BUILD_DIR/downloads"

apk-tools-extract "$BASE_ARCH" "$BASE_ALPINE_MIRROR" "$BASE_ALPINE_BRANCH" "$BUILD_DIR/downloads"

rootfs-mount-all "$ROOTFS_DIRECTORY"

apk-tools-install "$ROOTFS_DIRECTORY" "$BASE_ARCH" "$BASE_ALPINE_MIRROR" "$BASE_ALPINE_BRANCH"

#================================  a l p i n e  ===============================#

alpine-setup-prepare "$ROOTFS_DIRECTORY" "$CONFIG_DIR"

einfo "installing base alpine"

chroot "$ROOTFS_DIRECTORY" /bin/sh -c "set -a && . /config/config.env && set +a && /install-scripts/base.sh"

#==========================  p r o v i s i o n e r s  =========================#

einfo "installing provisioners $PROVISIONERS"

if [[ -n ${ADDITIONAL_PROVISIONERS+x} ]]; then
    additional-provisioners-copy "$ROOTFS_DIRECTORY" "$ADDITIONAL_PROVISIONERS"
fi

# loop through provisioners
for PROV in $PROVISIONERS; do
    einfo "installing provisioner $PROV"
    chroot "$ROOTFS_DIRECTORY" /bin/sh -c "set -a && . /config/config.env && set +a && /install-scripts/provisioners/$PROV.sh"
done

einfo "saving cache and lbu"

# Save lbu and apk cache
chroot "$ROOTFS_DIRECTORY" /install-scripts/cache-lbu.sh

# Move lbu and apk cache outside of rootfs
alpine-setup-backup "$ROOTFS_DIRECTORY" "$TARGET_DIR"

#==============================  t e a r d o w n  =============================#

einfo "tearing down root folder and unmounting"

rootfs-unmount-all "$ROOTFS_DIRECTORY"

rm -rf "$ROOTFS_DIRECTORY"
