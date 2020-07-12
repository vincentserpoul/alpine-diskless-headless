#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_ADD_PROV="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_ADD_PROV" ]]; then DIR_ADD_PROV="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_ADD_PROV""/../../scripts/utils.sh"
# shellcheck source=/dev/null
. """$DIR_ADD_PROV""/../../scripts/helpers.sh"

#============================  f u n c t i o n s  =============================#

additional-provisioners-copy() {
    local -r ROOTFS_DIR=$1
    local -r ADD_PROV_FOLDER=$2

    # copy the setup scripts inside the rootfs
    cp -r "$ADD_PROV_FOLDER"/* "$ROOTFS_DIR"/install-scripts/provisioners/
}
