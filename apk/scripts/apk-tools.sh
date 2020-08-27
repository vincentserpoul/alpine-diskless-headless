#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_APK_TOOLS="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_APK_TOOLS" ]]; then DIR_APK_TOOLS="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_APK_TOOLS""/../../scripts/utils.sh"

#==============================================================================#
#=============================== a p k - t o o l s ============================#
#==============================================================================#

#============================= d o w n l o a d ================================#

apk-tools-latest-version-get() {
    local -r LIST_URL=$1

    einfo "getting the latest stable apk static tools"

    wget -qO- "$LIST_URL" | grep apk-tools-static- | sed -n 's/.*href="\(.*\)".*/\1/p'
}

apk-tools-download() {
    local -r ARCH=$1
    local -r ALPINE_MIRROR=$2
    local -r ALPINE_BRANCH=$3
    local -r FILE_DIR=$4

    local -r LIST_URL="$ALPINE_MIRROR"/"$ALPINE_BRANCH"/main/"$ARCH"

    local -r FILE_NAME="$(apk-tools-latest-version-get "$LIST_URL")"

    local -r FILE_PATH="""$FILE_DIR""/""$ARCH""-""$FILE_NAME"""

    einfo "downloading apk static tools for $ARCH"

    dep-check wget

    if [ ! -f "$FILE_PATH" ]; then
        mkdir -p "$FILE_DIR"
        wget "$LIST_URL"/"$FILE_NAME" -O "$FILE_PATH"
    fi
}

apk-tools-extract() {
    local -r ARCH=$1
    local -r ALPINE_MIRROR=$2
    local -r ALPINE_BRANCH=$3
    local -r FILE_DIR=$4

    local -r LIST_URL="$ALPINE_MIRROR"/"$ALPINE_BRANCH"/main/"$ARCH"

    local -r FILE_NAME="$(apk-tools-latest-version-get "$LIST_URL")"

    local -r FILE_PATH="""$FILE_DIR""/""$ARCH""-""$FILE_NAME"""

    local -r XTRACT_DIR="$DIR_APK_TOOLS"/../apk-tools-static

    rm -rf "$XTRACT_DIR" >/dev/null 2>&1 || true
    mkdir -p "$XTRACT_DIR"
    tar xzf "$FILE_PATH" -C "$XTRACT_DIR"
}

#============================== i n s t a l l =================================#

alpine_get_keys() {
    local -r ROOTFS_DIR=$1

    local -r ALPINE_KEYS_URL="https://alpinelinux.org/keys/"
    local -r ALPINE_KEYS_DIR=$ROOTFS_DIR"/etc/apk/keys/"

    einfo "getting alpine keys"

    wget -qO- "$ALPINE_KEYS_URL" |
        grep alpine-devel@lists.alpinelinux.org |
        sed -n 's/.*href="\(.*\)".*/\1/p' |
        xargs printf "https://alpinelinux.org/keys/%s\n" |
        xargs wget -q -P "$ALPINE_KEYS_DIR"

}

apk-tools-install() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r ALPINE_MIRROR=$3
    local -r ALPINE_BRANCH=$4

    # enabling dns resolution in chroot
    mkdir -p "$ROOTFS_DIR"/etc
    echo -e 'nameserver 8.8.8.8\nnameserver 2620:0:ccc::2' >"$ROOTFS_DIR"/etc/resolv.conf

    # copying apk-static
    mkdir -p "$ROOTFS_DIR"/usr/local/sbin/
    cp "$DIR_APK_TOOLS"/../apk-tools-static/sbin/apk.static "$ROOTFS_DIR"/usr/local/sbin/

    alpine_get_keys "$ROOTFS_DIR"

    einfo "installing apk tools in ""$ROOTFS_DIR"""
    # we could run without chroot, but it's safer with
    chroot "$ROOTFS_DIR" /usr/local/sbin/apk.static \
        --repository "$ALPINE_MIRROR"/"$ALPINE_BRANCH"/main \
        --arch "$ARCH" \
        --update-cache \
        --initdb \
        add alpine-base

    # cleanup
    rm "$ROOTFS_DIR"/usr/local/sbin/apk.static
}
