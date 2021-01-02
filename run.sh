#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup_run SIGINT SIGTERM ERR EXIT

#==============================================================================#

readonly VERSION="0.1.4"

#============================== i n c l u d e s ===============================#

DIR_BASE=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

if [[ ! -d "$DIR_BASE" ]]; then DIR_BASE="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_BASE""/scripts/utils.sh"
# shellcheck source=/dev/null
. """$DIR_BASE""/scripts/helpers.sh"

#========================= u s a g e  &  c l e a n u p ========================#

usage() {
    echo "alpine-diskless-headless-run ""$VERSION"""
    echo

    cat <<EOF
Usage: ./run.sh [options]

The goal of this script is to create a diskless, headless install of alpine
linux for your SBC (rpi, rockpro64...), directly from your x86 computer.

Just insert a sdcard and run it with the right parameters.

It has a few dependencies: wget, binfmt-support, qemu-user-static, ssh, parted, dosfstools

Example:
  sudo ./run.sh -c "$(pwd)"/example/pleine-lune-rpi3b+/config.env -t "$(pwd)"/example/pleine-lune-rpi3b+/target -H rpi -d /dev/sda -f

Options and environment variables:

  -c CONFIG_FILE_PATH         path of the config.env file

  -a ADDITIONAL_PROVISIONERS  path of the folder containing additional provisioner scripts
                              Default: empty

  -t TARGET_DIR               dir where tar.gz will be created
                              Default: config dir

  -H TARGET_HW                which SMB you are targeting.
                              Options: rpi
                              Default: rpi

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

cleanup_run() {
    trap - SIGINT SIGTERM ERR EXIT
    einfo "nothing to clean for run.sh"
}

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

parse_params() {
    CONFIG_FILE_PATH=''
    ADDITIONAL_PROVISIONERS=''
    TARGET_DIR=''
    TARGET_HW=''
    DEVICE_NAME=''
    FORCE_DEV_WRITE=false

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
        -H | --target-hardware)
            TARGET_HW="${2-}"
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
    # [[ -z "${param-}" ]] && die "Missing required parameter: param"
    # [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

    return 0
}

parse_params "$@"

#===================================  M a i n  ================================#

root-check

einfo "running alpine-diskless-headless-run"

# apk
"$DIR_BASE"/apk/build.sh -c "$CONFIG_FILE_PATH" -a "$ADDITIONAL_PROVISIONERS" -t "$TARGET_DIR"

# if hardware not specified, we don't continue
if [[ -z ${TARGET_HW+x} ]]; then
    einfo "finished successfully!"
    exit 0
fi

# hardware boot
"$DIR_BASE"/hw/build.sh -c "$CONFIG_FILE_PATH" -t "$TARGET_DIR" -H "$TARGET_HW"

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
