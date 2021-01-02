#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup_apk_build SIGINT SIGTERM ERR EXIT

#==============================================================================#

readonly VERSION="0.1.4"

#============================== i n c l u d e s ===============================#

BUILD_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
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

#========================= u s a g e  &  c l e a n u p ========================#

usage() {
    echo "alpine-diskless-headless-apk-build ""$VERSION"""
    echo

    cat <<EOF
Usage: ./build.sh [options]

The goal of this script is to create a diskless, headless install of alpine
linux for your SBC (rpi, rockpro64...), directly from your x86 computer.

It has a few dependencies: wget, binfmt-support, qemu-user-static, ssh

Example:
  sudo ./build.sh -c "$(pwd)"/example/pleine-lune-rpi3b+/config.env -t "$(pwd)"/example/pleine-lune-rpi3b+/target

Options and environment variables:

  -c CONFIG_FILE_PATH         path of the config.env file

  -a ADDITIONAL_PROVISIONERS  path of the folder containing additional provisioner scripts
                              Default: empty

  -t TARGET_DIR               dir where tar.gz will be created
                              Default: config dir

  -h                          show this help message and exit.

Each option can be also provided by environment variable. If both option and
variable is specified and the option accepts only one argument, then the
option takes precedence.

https://github.com/vincentserpoul/alpine-diskless-headless
EOF
    exit
}

cleanup_apk_build() {
    trap - SIGINT SIGTERM ERR EXIT

    einfo "tearing down root folder and unmounting"

    rootfs-unmount-all "$ROOTFS_DIRECTORY"

    rm -rf "$ROOTFS_DIRECTORY"
}

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

parse_params() {
    CONFIG_FILE_PATH=''
    ADDITIONAL_PROVISIONERS=''
    TARGET_DIR=''

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        -c | --config-file-path)
            CONFIG_FILE_PATH="${2-}"
            shift
            ;;
        -a | --additional-provisioners)
            ADDITIONAL_PROVISIONERS="${2-}"
            shift
            ;;
        -t | --target-dir)
            TARGET_DIR="${2-}"
            shift
            ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    # args=("$@")

    # check required params and arguments
    [[ -z "${CONFIG_FILE_PATH+x}" ]] && die "Missing required parameter: -c config file path"

    # [[ -z "${param-}" ]] && die "Missing required parameter: param"
    # [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

    return 0
}

parse_params "$@"

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
