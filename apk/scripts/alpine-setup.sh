#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_ALPINE_SETUP="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_ALPINE_SETUP" ]]; then DIR_ALPINE_SETUP="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_ALPINE_SETUP""/../../scripts/utils.sh"
# shellcheck source=/dev/null
. """$DIR_ALPINE_SETUP""/../../scripts/helpers.sh"

#============================= a p k  c a c h e ===============================#

alpine-setup-apkcache-save() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r BUILD_HOSTNAME=$3
    local -r ALPINE_VERSION=$4

    einfo "backing up apk cache outside of rootfs"

    mkdir -p "$DIR_ALPINE_SETUP"/../apkovl

    tar czf \
        "$(helpers-apkcache-filepath-get "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME")" \
        -C "$ROOTFS_DIR"/var/cache/apk \
        .
}

#=================================== l b u ====================================#

alpine-setup-apkovl-save() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r BUILD_HOSTNAME=$3
    local -r ALPINE_VERSION=$4

    einfo "backing up apkovl outside of rootfs"

    mkdir -p "$DIR_ALPINE_SETUP"/../apkovl
    mv "$ROOTFS_DIR"/target/alpine.apkovl.tar.gz \
        "$(helpers-apkovl-filepath-get "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME")"
}

#=================================== s s h ====================================#

alpine-setup-ssh-gen() {
    local SUDO_USER_LOCAL
    if [[ -v SUDO_USER ]]; then
        SUDO_USER_LOCAL="$SUDO_USER"
    else
        SUDO_USER_LOCAL="root"
    fi
    local -r SSH_KEY_SECRET_PATH="$DIR_ALPINE_SETUP"/../secrets/ssh/authorized_keys
    local -r USER_HOME=$(eval echo ~"$SUDO_USER_LOCAL")
    local -r SSH_KEY_PATH="$USER_HOME/.ssh/id_ed25519_alpine_diskless"

    if [[ ! -d "$DIR_ALPINE_SETUP"/../secrets/ssh || ! -f "$SSH_KEY_PATH" ]]; then
        einfo "generating the ssh key to connect to your device:"
        mkdir -p "$USER_HOME"/.ssh
        ssh-keygen -q -o -a 100 -t ed25519 -f "$SSH_KEY_PATH" -N ""
        chown "$SUDO_USER_LOCAL":"$SUDO_USER_LOCAL" "$SSH_KEY_PATH"
        chmod 0600 "$SSH_KEY_PATH"
        mkdir -p "$DIR_ALPINE_SETUP"/../secrets/ssh
        cat "$SSH_KEY_PATH".pub >"$SSH_KEY_SECRET_PATH"
    fi
}

#=================================== 2 f a ====================================#

alpine-setup-2fa-save() {
    local -r ROOTFS_DIR=$1

    if [[ ! -d "$DIR_ALPINE_SETUP/../secrets" || ! -d \
        "$DIR_ALPINE_SETUP/../secrets/2fa" || ! -f \
        "$DIR_ALPINE_SETUP/../secrets/2fa/google_authenticator" ]] \
            ; then
        mkdir -p "$DIR_ALPINE_SETUP/../secrets/2fa"
        cat "$ROOTFS_DIR/home/maintenance/.google_authenticator" >"$DIR_ALPINE_SETUP/../secrets/2fa/google_authenticator"
    fi
}

#==============================================================================#
#==================================== M A I N =================================#
#==============================================================================#

alpine-prepare() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r BUILD_HOSTNAME=$3
    local -r ALPINE_VERSION=$4

    # create a secure ssh key
    alpine-setup-ssh-gen

    cp -r "$BUILD_DIR"/scripts/chroot "$ROOTFS_DIR"/
    cp -r "$BUILD_DIR"/secrets "$ROOTFS_DIR"/

}

alpine-teardown() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r BUILD_HOSTNAME=$3
    local -r ALPINE_VERSION=$4

    # IMPORTANT CLEANUP - DO NOT ERASE EVEN THOUGH NOT IN THE LCCAL BACKUP
    rm -rf "$ROOTFS_DIR"/chroot
    rm -rf "$ROOTFS_DIR"/secrets

    alpine-setup-apkcache-save "$ROOTFS_DIR" "$ARCH" "$BUILD_HOSTNAME" "$ALPINE_VERSION"
    alpine-setup-apkovl-save "$ROOTFS_DIR" "$ARCH" "$BUILD_HOSTNAME" "$ALPINE_VERSION"
    alpine-setup-2fa-save "$ROOTFS_DIR"
}
