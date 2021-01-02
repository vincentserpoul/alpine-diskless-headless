#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup_hw_build SIGINT SIGTERM ERR EXIT

#==============================================================================#

readonly VERSION="0.1.4"

#============================== i n c l u d e s ===============================#

BUILD_HW_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
if [[ ! -d "$BUILD_HW_DIR" ]]; then BUILD_HW_DIR="$PWD"; fi

# shellcheck source=/dev/null
. """$BUILD_HW_DIR""/../scripts/utils.sh"
# shellcheck source=/dev/null
. """$BUILD_HW_DIR""/../scripts/helpers.sh"

#========================= u s a g e  &  c l e a n u p ========================#

usage() {
    echo "alpine-diskless-headless-hw-build ""$VERSION"""
    echo

    cat <<EOF
Usage: ./build.sh [options]

The goal of this script is to build a boot for a specific hardware.

Example:
  sudo ./run.sh -c "$(pwd)"/example/pleine-lune-rpi3b+/config.env -t "$(pwd)"/example/pleine-lune-rpi3b+/target -H rpi

Options and environment variables:

  -c CONFIG_FILE_PATH         path of the config.env file

  -t TARGET_DIR               dir where tar.gz will be created
                              Default: config dir

  -H TARGET_HW                which SMB you are targeting.
                              Options: rpi
                              Default: rpi

  -h                          show this help message and exit.

Each option can be also provided by environment variable. If both option and
variable is specified and the option accepts only one argument, then the
option takes precedence.

https://github.com/vincentserpoul/alpine-diskless-headless
EOF
    exit
}

cleanup_hw_build() {
    trap - SIGINT SIGTERM ERR EXIT
    einfo "nothing to clean for hw/build.sh"
}

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

parse_params() {
    CONFIG_FILE_PATH=''
    TARGET_DIR=''
    TARGET_HW=''

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        -c | --config-file-path)
            CONFIG_FILE_PATH="${2-}"
            shift
            ;;
        -t | --target-dir)
            TARGET_DIR="${2-}"
            shift
            ;;
        -H | --target-hardware)
            TARGET_HW="${2-}"
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
    [[ -z "${TARGET_HW+x}" ]] && die "Missing required parameter: -H specific hardware, like rpi"

    # [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

    return 0
}

parse_params "$@"

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

#================================  h a r d w a r e  ===========================#

einfo "checking target hardware"

if [[ ! -d "$BUILD_HW_DIR/$TARGET_HW" ]]; then
    die "$BUILD_HW_DIR/$TARGET_HW is not a dir"
fi

#===================================  M a i n  ================================#

./"$BUILD_HW_DIR"/"$TARGET_HW"/build.sh -c "$CONFIG_FILE_PATH" -t "$TARGET_DIR"
