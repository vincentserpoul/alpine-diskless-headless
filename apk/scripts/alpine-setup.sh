#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_ALPINE_SETUP="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_ALPINE_SETUP" ]]; then DIR_ALPINE_SETUP="$PWD"; fi

. """$DIR_ALPINE_SETUP""/../../scripts/utils.sh"
. """$DIR_ALPINE_SETUP""/../../scripts/helpers.sh"

#================================ f u n c t i o n s ===========================#

alpine-setup-hostname() {
    local -r ROOTFS_DIR=$1
    local -r BUILD_HOSTNAME=$2

    einfo "setting up hostname ""$BUILD_HOSTNAME"""

    chroot "$ROOTFS_DIR" setup-hostname -n "$BUILD_HOSTNAME"
    chroot "$ROOTFS_DIR" hostname "$BUILD_HOSTNAME"

    printf "Welcome to %s!\n\n" "$BUILD_HOSTNAME" >"$ROOTFS_DIR"/etc/motd
}

alpine-setup-repositories() {
    local -r ROOTFS_DIR=$1
    local -r ALPINE_MIRROR=$2
    local -r ALPINE_BRANCH=$3

    einfo "setting up apk repos with main and community"

    mkdir -p "$ROOTFS_DIR"/etc/apk
    printf '%s\n' \
        "$ALPINE_MIRROR/$ALPINE_BRANCH/main" \
        "$ALPINE_MIRROR/$ALPINE_BRANCH/community" \
        >"$ROOTFS_DIR"/etc/apk/repositories

    chroot "$ROOTFS_DIR" setup-apkrepos -1
    # chroot "$ROOTFS_DIR" apk update --allow-untrusted
}

alpine-setup-keymap() {
    local -r ROOTFS_DIR=$1

    einfo "setting up keymap"

    chroot "$ROOTFS_DIR" setup-keymap us us
}

alpine-setup-dns() {
    local -r ROOTFS_DIR=$1

    einfo "setting up dns"

    chroot "$ROOTFS_DIR" setup-dns -d "none" -n 8.8.8.8
}

alpine-setup-timezone() {
    local -r ROOTFS_DIR=$1
    local -r TIMEZONE=$2

    einfo "setting up timezone ""$TIMEZONE"""

    chroot "$ROOTFS_DIR" setup-timezone -z "$TIMEZONE"
}

alpine-setup-networking() {
    local -r ROOTFS_DIR=$1

    einfo "setting up network interfaces"

    cat <<EOF >"$ROOTFS_DIR"/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hostname $BUILD_HOSTNAME

EOF
}

alpine-setup-install-essentials() {
    local -r ROOTFS_DIR=$1

    einfo "installing essential packages"

    chroot "$ROOTFS_DIR" apk update

    # adding the apk cache in the lbu
    chroot "$ROOTFS_DIR" lbu add /var/cache/apk

    chroot "$ROOTFS_DIR" apk add \
        openssh rsync sudo eudev haveged chrony avahi tzdata

}

alpine-setup-initd() {
    local -r ROOTFS_DIR=$1

    einfo "adding services to startup"

    for service in devfs dmesg mdev; do
        chroot "$ROOTFS_DIR" rc-update add "$service" sysinit
    done

    for service in modules sysctl hostname bootmisc swclock syslog swap; do
        chroot "$ROOTFS_DIR" rc-update add "$service" boot
    done

    for service in haveged sshd chronyd local networking avahi-daemon; do
        chroot "$ROOTFS_DIR" rc-update add "$service" default
    done

    for service in mount-ro killprocs savecache; do
        chroot "$ROOTFS_DIR" rc-update add "$service" shutdown
    done
}

#============================== u s e r =======================================#

alpine-setup-user() {
    local -r ROOTFS_DIR=$1

    einfo "setting up user maintenance"

    chroot "$ROOTFS_DIR" /usr/sbin/addgroup -S maintenance
    chroot "$ROOTFS_DIR" /usr/sbin/adduser maintenance --ingroup maintenance --disabled-password

    mkdir -p "$ROOTFS_DIR"/home/maintenance

    # adding home to lbu
    chroot "$ROOTFS_DIR" lbu add /home/maintenance
}

#=============================== s s h ========================================#

alpine-setup-ssh() {
    local -r ROOTFS_DIR=$1

    einfo "securing /etc/ssh/sshd_config"

    cat <<EOF >>"$ROOTFS_DIR"/etc/ssh/sshd_config

AuthenticationMethods publickey,keyboard-interactive

AllowUsers maintenance

PermitRootLogin no
PasswordAuthentication no

ChallengeResponseAuthentication yes

EOF

    # copy ssh keys
    mkdir -p "$ROOTFS_DIR"/home/maintenance/.ssh
    cat "$DIR_ALPINE_SETUP"/../secrets/ssh/authorized_keys >"$ROOTFS_DIR"/home/maintenance/.ssh/authorized_keys

    # setting up 2fa
    alpine-setup-ssh-2fa "$ROOTFS_DIR"

}

alpine-setup-ssh-2fa() {
    local -r ROOTFS_DIR=$1

    einfo "setup 2fa"

    chroot "$ROOTFS_DIR" apk add openssh-server-pam google-authenticator

    mkdir -p "$ROOTFS_DIR"/etc/pam.d
    echo "auth required pam_google_authenticator.so" >"$ROOTFS_DIR"/etc/pam.d/sshd

    printf "\nUsePAM yes\n" >>"$ROOTFS_DIR"/etc/ssh/sshd_config

    local -r GA_KEY="$(cat """$DIR_ALPINE_SETUP"""/../secrets/2fa/google_authenticator)"

    cat <<EOF >>"$ROOTFS_DIR"/home/maintenance/.google_authenticator
$GA_KEY
" RATE_LIMIT 3 30
" WINDOW_SIZE 17
" TOTP_AUTH

EOF
}

#================================= w l a n ====================================#

alpine-setup-wlan() {
    local -r ROOTFS_DIR=$1
    local -r SSID="$(cat """$DIR_ALPINE_SETUP"""/../secrets/wlan/ssid)"
    local -r PSK="$(cat """$DIR_ALPINE_SETUP"""/../secrets/wlan/psk)"

    einfo "setting up wlan"

    chroot "$ROOTFS_DIR" apk add wpa_supplicant

    chroot "$ROOTFS_DIR" rc-update add wpa_supplicant default

    cat <<EOF >>"$ROOTFS_DIR"/etc/wpa_supplicant/wpa_supplicant.conf
network={
	ssid="$SSID"
	key_mgmt=WPA-PSK
	psk=$PSK
}
EOF

    cat <<EOF >>"$ROOTFS_DIR"/etc/network/interfaces
auto wlan0
iface wlan0 inet dhcp
    hostname $BUILD_HOSTNAME

EOF
}

#=================================== l b u ====================================#

alpine-setup-lbu-commit() {
    local -r ROOTFS_DIR=$1

    einfo "saving to lbu"

    chroot "$ROOTFS_DIR" lbu add /var/cache

    chroot "$ROOTFS_DIR" lbu pkg /alpine.apkovl.tar.gz
}

alpine-setup-apkovl-save() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r ALPINE_VERSION=$3
    local -r BUILD_HOSTNAME=$4

    einfo "backing up apkovl outside of rootfs"

    mkdir -p "$DIR_ALPINE_SETUP"/../apkovl

    mv "$ROOTFS_DIR"/alpine.apkovl.tar.gz "$(helpers-apkovl-filepath-get "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME")"
}

#==============================================================================#
#==================================== M A I N =================================#
#==============================================================================#

alpine-setup() {
    local -r ROOTFS_DIR=$1
    local -r ARCH=$2
    local -r BUILD_HOSTNAME=$3
    local -r ALPINE_MIRROR=$4
    local -r ALPINE_BRANCH=$5
    local -r TIMEZONE=$6
    local -r ALPINE_VERSION=$7

    # alpine_dump_keys "$ROOTFS_DIR"
    alpine-setup-hostname "$ROOTFS_DIR" "$BUILD_HOSTNAME"
    alpine-setup-repositories "$ROOTFS_DIR" "$ALPINE_MIRROR" "$ALPINE_BRANCH"
    alpine-setup-dns "$ROOTFS_DIR"
    alpine-setup-keymap "$ROOTFS_DIR"
    alpine-setup-timezone "$ROOTFS_DIR" "$TIMEZONE"
    alpine-setup-networking "$ROOTFS_DIR"
    alpine-setup-install-essentials "$ROOTFS_DIR"
    alpine-setup-initd "$ROOTFS_DIR"
    alpine-setup-user "$ROOTFS_DIR"
    alpine-setup-ssh "$ROOTFS_DIR"
    alpine-setup-wlan "$ROOTFS_DIR"

    alpine-setup-lbu-commit "$ROOTFS_DIR"
    alpine-setup-apkovl-save "$ROOTFS_DIR" "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME"
}
