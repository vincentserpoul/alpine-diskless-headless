#!/usr/bin/env bash

set -Eeuo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_ADD_PROV=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
if [[ ! -d "$DIR_ADD_PROV" ]]; then DIR_ADD_PROV="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_ADD_PROV""/../../scripts/utils.sh"
# shellcheck source=/dev/null
. """$DIR_ADD_PROV""/../../scripts/helpers.sh"

#============================  f u n c t i o n s  =============================#

additional-provisioners-copy() {
    local -r ROOTFS_DIR=$1
    local -r ADD_PROV_FOLDER=$2

    if [ "$(find "$ADD_PROV_FOLDER" -mindepth 1 -print -quit 2>/dev/null)" ]; then
        einfo "copying additional provisioners present in folder $ADD_PROV_FOLDER"

        # copy the setup scripts inside the rootfs
        cp -a "$ADD_PROV_FOLDER"/* "$ROOTFS_DIR"/install-scripts/provisioners/
    else
        einfo "no additional provisioner to copy"
    fi

}
