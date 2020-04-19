#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_APK_TOOLS="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_APK_TOOLS" ]]; then DIR_APK_TOOLS="$PWD"; fi

. """$DIR_APK_TOOLS""/../../scripts/utils.sh"

#==============================================================================#
#=============================== a p k - t o o l s ============================#
#==============================================================================#

#=============================== u t i l s ====================================#

apk-tools-mount-rootfs-dir-all() {
    local -r ROOTFS_DIR=$1

    einfo "mounting proc, sys, dev in ""$ROOTFS_DIR"""

    mkdir -p "$ROOTFS_DIR"/proc
    mkdir -p "$ROOTFS_DIR"/sys
    mkdir -p "$ROOTFS_DIR"/dev

    mount -v -t proc none "$ROOTFS_DIR"/proc/
    mount -v --rbind /sys "$ROOTFS_DIR"/sys/
    mount --make-rprivate "$ROOTFS_DIR"/sys/
    mount -v --rbind /dev "$ROOTFS_DIR"/dev/
    mount --make-rprivate "$ROOTFS_DIR"/dev/
}

apk-tools-umount-rootfs-dir-all() {
    local -r ROOTFS_DIR=$1

    einfo "unmounting proc, sys, dev from ""$ROOTFS_DIR"""

    umount "$ROOTFS_DIR"/dev --lazy >/dev/null 2>&1 || true
    umount "$ROOTFS_DIR"/proc --lazy >/dev/null 2>&1 || true
    umount "$ROOTFS_DIR"/sys --lazy >/dev/null 2>&1 || true

    rmdir "$ROOTFS_DIR"/proc >/dev/null 2>&1 || true
    rmdir "$ROOTFS_DIR"/sys >/dev/null 2>&1 || true
    rmdir "$ROOTFS_DIR"/dev >/dev/null 2>&1 || true

}

#============================= d o w n l o a d ================================#

apk-tools-latest-version-get() {
    local -r LIST_URL=$1

    einfo "getting the latest stable apk static tools"

    wget -qO- "$LIST_URL" | grep apk-tools-static- | sed -n 's/.*href="\(.*\)".*/\1/p'
}

apk-tools-downloadx() {
    local -r ALPINE_MIRROR=$1
    local -r ALPINE_BRANCH=$2

    local -r LIST_URL="$ALPINE_MIRROR"/"$ALPINE_BRANCH"/main/"$ARCH"

    local -r FILE_DIR="""$DIR_APK_TOOLS""/../downloads"

    local -r FILE_NAME="$(apk-tools-latest-version-get "$LIST_URL")"

    local -r FILE_PATH="""$FILE_DIR""/""$FILE_NAME"""

    einfo "dowloading apk static tools"

    dep-check wget

    if [ ! -f "$FILE_PATH" ]; then
        mkdir -p "$FILE_DIR"
        wget "$LIST_URL"/"$FILE_NAME" -O "$FILE_PATH"
    fi

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
    cat /etc/resolv.conf >"$ROOTFS_DIR"/etc/resolv.conf

    # copying apk-static
    mkdir -p "$ROOTFS_DIR"/usr/local/sbin/
    cp "$DIR_APK_TOOLS"/../apk-tools-static/sbin/apk.static "$ROOTFS_DIR"/usr/local/sbin/

    # because otherwise /etc/apk/arch says x86
    # cp /bin/qemu-aarch64-static "$ROOTFS_DIR"/usr/local/sbin/

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
    rm -rf "$ROOTFS_DIR"/usr/local/sbin/apk.static
}
