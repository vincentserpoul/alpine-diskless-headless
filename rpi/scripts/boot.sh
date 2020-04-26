#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_BOOT="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_BOOT" ]]; then DIR_BOOT="$PWD"; fi

. """$DIR_ALPINE""/helpers.sh"
. """$DIR_BOOT""/../../scripts/utils.sh"
. """$DIR_ALPINE""/../../scripts/helpers.sh"

#================================  b o o t  ===================================#

boot-cmdline() {
    local -r WORK_DIR=$1

    einfo "modifying cmdline.txt for rpi"

    echo "modules=loop,squashfs,sd-mod,usb-storage quiet dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 dtoverlay=pi3-miniuart-bt elevator=deadline fsck.repair=yes cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1 use_hierarchy=1" >"$WORK_DIR"/cmdline.txt

}

boot-usercfg() {
    local -r WORK_DIR=$1

    einfo "creating usercfg.txt for rpi"

    cat <<EOF >>"$WORK_DIR"/usercfg.txt
enable_uart=1
disable_overscan=1
dtparam=sd_overclock=100
hdmi_drive=2
dtparam=audio=on
disable_splash=1
boot_delay=1
EOF
}

boot-compress() {
    local -r WORK_DIR=$1
    local -r ARCH=$2
    local -r ALPINE_VERSION=$3

    einfo "compressing the alpine boot"

    mkdir -p "$DIR_BOOT"/../boot
    tar czf "$(helpers-hardware-filepath-get "rpi" "$ARCH" "$ALPINE_VERSION")" -C "$WORK_DIR" .
}

#==============================================================================#
#==================================== M A I N =================================#
#==============================================================================#

boot-update() {
    local -r ARCH=$1
    local -r ALPINE_VERSION=$2

    local -r WORK_DIR="$(helpers-workdir-name-get """$ARCH""" """$ALPINE_VERSION""")"

    boot-cmdline "$WORK_DIR"
    boot-usercfg "$WORK_DIR"
    boot-compress "$WORK_DIR" "$ARCH" "$ALPINE_VERSION"

    rm -rf "$WORK_DIR"
}
