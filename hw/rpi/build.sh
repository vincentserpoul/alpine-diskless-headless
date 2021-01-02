#!/usr/bin/env bash

set -Eeuo pipefail

#============================== i n c l u d e s ===============================#

BUILD_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
if [[ ! -d "$BUILD_DIR" ]]; then BUILD_DIR="$PWD"; fi

# shellcheck source=/dev/null
. """$BUILD_DIR""/../../scripts/utils.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/alpine.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/boot.sh"

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

parse_params() {
    CONFIG_FILE_PATH=''

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
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    # args=("$@")

    # check required params and arguments
    [[ -z "${CONFIG_FILE_PATH+x}" ]] && die "Missing required parameter: -c config file path"

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

#===================================  M a i n  ================================#

# root-check

einfo "Getting the necessary files for the RPi to boot with alpine"

alpine-download "$BASE_ARCH" "$BASE_ALPINE_MIRROR" "$BASE_ALPINE_BRANCH" "$BASE_ALPINE_VERSION"

alpine-extract "$BASE_ARCH" "$BASE_ALPINE_VERSION"

boot-update "$TARGET_DIR" "$BASE_ARCH" "$BASE_ALPINE_VERSION"
