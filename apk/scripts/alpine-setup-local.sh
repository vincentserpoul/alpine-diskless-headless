#!/usr/bin/env sh

set -euo

#==============================================================================#

DIR_ALPINE_SETUP=$(CDPATH="cd -- $(dirname -- "$0")" && pwd)

#================================ f u n c t i o n s ===========================#

alpine_setup_hostname() {
    BUILD_HOSTNAME=$1

    setup-hostname -n "$BUILD_HOSTNAME"
    hostname "$BUILD_HOSTNAME"

    printf "Welcome to %s!\n\n" "$BUILD_HOSTNAME" >/etc/motd
}

alpine_setup_repositories() {
    ALPINE_MIRROR=$1
    ALPINE_BRANCH=$2

    mkdir -p /etc/apk
    printf '%s\n' \
        "$ALPINE_MIRROR/$ALPINE_BRANCH/main" \
        "$ALPINE_MIRROR/$ALPINE_BRANCH/community" \
        >/etc/apk/repositories

    setup-apkrepos -1
}

alpine_setup_keymap() {
    setup-keymap us us
}

alpine_setup_dns() {
    setup-dns -d "none" -n 8.8.8.8
}

alpine_setup_timezone() {
    TIMEZONE=$1
    setup-timezone -z "$TIMEZONE"
}

alpine_setup_networking() {
    cat <<EOF >/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hostname $BUILD_HOSTNAME

EOF
}

alpine_setup_install_essentials() {
    apk update

    apk add \
        openssh rsync sudo eudev haveged chrony avahi tzdata google-authenticator

}

alpine_setup_initd() {

    for service in devfs dmesg mdev hwdrivers modloop; do
        rc-update add "$service" sysinit
    done

    for service in modules sysctl hostname bootmisc swclock syslog swap; do
        rc-update add "$service" boot
    done

    for service in haveged sshd chronyd local networking avahi-daemon; do
        rc-update add "$service" default
    done

    for service in mount-ro killprocs savecache; do
        rc-update add "$service" shutdown
    done
}

#============================== u s e r =======================================#

alpine_setup_user() {

    /usr/sbin/addgroup -S maintenance
    /usr/sbin/adduser maintenance --ingroup maintenance --disabled-password

    mkdir -p /home/maintenance

    # adding home to lbu
    lbu add /home/maintenance
}

#=============================== s s h ========================================#

alpine_setup_ssh() {
    cat <<EOF >>/etc/ssh/sshd_config

AuthenticationMethods publickey,keyboard-interactive

AllowUsers maintenance

PermitRootLogin no
PasswordAuthentication no

ChallengeResponseAuthentication yes

EOF

    # copy ssh keys
    mkdir -p /home/maintenance/.ssh
    cat "$DIR_ALPINE_SETUP"/secrets/ssh/authorized_keys >/home/maintenance/.ssh/authorized_keys

    # setting up 2fa
    alpine_setup_ssh_2fa

}

alpine_setup_ssh_2fa() {
    apk add openssh-server-pam google-authenticator

    mkdir -p /etc/pam.d
    echo "auth required pam_google_authenticator.so" >/etc/pam.d/sshd

    printf "\nUsePAM yes\n" >>/etc/ssh/sshd_config

    GA_KEY="$(cat "$DIR_ALPINE_SETUP"/secrets/2fa/google_authenticator)"

    cat <<EOF >>/home/maintenance/.google_authenticator
$GA_KEY
" RATE_LIMIT 3 30
    " WINDOW_SIZE 17
" TOTP_AUTH

EOF
}

#================================= w l a n ====================================#

alpine_setup_wlan() {
    SSID="$(cat "$DIR_ALPINE_SETUP"/secrets/wlan/ssid)"
    PSK="$(cat "$DIR_ALPINE_SETUP"/secrets/wlan/psk)"

    apk add wpa_supplicant

    rc-update add wpa_supplicant default

    cat <<EOF >>/etc/wpa_supplicant/wpa_supplicant.conf
network={
	ssid="$SSID"
	key_mgmt=WPA-PSK
	psk=$PSK
}
EOF

    cat <<EOF >>/etc/network/interfaces
auto wlan0
iface wlan0 inet dhcp
    hostname $BUILD_HOSTNAME

EOF
}

#=================================== l b u ====================================#

alpine_setup_lbu_commit() {
    lbu pkg "$DIR_ALPINE_SETUP"/alpine.apkovl.tar.gz
}

#==============================================================================#
#==================================== M A I N =================================#
#==============================================================================#

BUILD_HOSTNAME=$1
ALPINE_MIRROR=$2
ALPINE_BRANCH=$3
TIMEZONE=$4

mkdir -p /etc
printf 'nameserver 8.8.8.8\nnameserver 2620:0:ccc::2' >/etc/resolv.conf

alpine_setup_hostname "$BUILD_HOSTNAME"
alpine_setup_repositories "$ALPINE_MIRROR" "$ALPINE_BRANCH"
alpine_setup_dns
alpine_setup_keymap
alpine_setup_timezone "$TIMEZONE"
alpine_setup_networking
alpine_setup_install_essentials
alpine_setup_initd
alpine_setup_user
alpine_setup_ssh
alpine_setup_wlan

alpine_setup_lbu_commit
