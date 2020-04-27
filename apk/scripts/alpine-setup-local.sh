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

EOF
}

alpine_setup_install_essentials() {
    apk update

    apk add \
        openssh rsync sudo eudev haveged chrony avahi dbus tzdata

}

alpine_setup_reinstall_pkg_boot() {
    cat <<EOF >/etc/init.d/reinstall-pkg
#!/sbin/openrc-run

description="Install necessary packages at boot"

depend() {
  after modules
  need localmount
}

start() {
    /sbin/apk fix
}
EOF

    chmod +x /etc/init.d/reinstall-pkg
    lbu include /etc/init.d/reinstall-pkg
}

alpine_setup_initd() {

    for service in devfs dmesg mdev hwdrivers modloop; do
        rc-update add "$service" sysinit
    done

    for service in modules sysctl hostname bootmisc swclock syslog swap reinstall-pkg; do
        rc-update add "$service" boot
    done

    for service in dbus haveged sshd chronyd local networking avahi-daemon; do
        rc-update add "$service" default
    done

    for service in mount-ro killprocs savecache; do
        rc-update add "$service" shutdown
    done
}

#============================== u s e r =======================================#

alpine_setup_user() {

    alpine_change_pass root

    /usr/sbin/addgroup -S maintenance
    /usr/sbin/adduser maintenance --ingroup maintenance --disabled-password --shell /bin/ash

    mkdir -p /home/maintenance

    alpine_change_pass maintenance

    alpine_sudoers maintenance

    # adding home to lbu
    lbu add /home/maintenance
}

alpine_change_pass() {
    USER=$1
    PASS="$(cat "$DIR_ALPINE_SETUP"/secrets/users/"$USER".password)"

    echo "$USER":"$PASS" | /usr/sbin/chpasswd
}

alpine_sudoers() {
    GROUP=$1
    echo "%""$GROUP"" ALL=(ALL) ALL" >/etc/sudoers.d/maintenance
}

#=============================== s s h ========================================#

alpine_setup_ssh() {

    sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#LogLevel INFO/LogLevel INFO/' /etc/ssh/sshd_config
    sed -i 's/#ListenAddress ::/ListenAddress ::/' /etc/ssh/sshd_config
    sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config

    cat <<EOF >>/etc/ssh/sshd_config

AuthenticationMethods publickey,keyboard-interactive
AllowUsers maintenance

EOF

    # copy ssh keys
    mkdir -p /home/maintenance/.ssh
    cat "$DIR_ALPINE_SETUP"/secrets/ssh/authorized_keys >/home/maintenance/.ssh/authorized_keys

    # setting up 2fa
    alpine_setup_ssh_2fa

    # generate ssh keys - NOT WORKING YET
    alpine_generate_ssh_keys
}

alpine_setup_ssh_2fa() {
    apk add openssh-server-pam google-authenticator

    mkdir -p /etc/pam.d
    echo "auth required pam_google_authenticator.so" >/etc/pam.d/sshd

    sed -i 's/#UsePAM no/UsePAM yes/' /etc/ssh/sshd_config

    GA_KEY="$(cat "$DIR_ALPINE_SETUP"/secrets/2fa/google_authenticator)"

    cat <<EOF >>/home/maintenance/.google_authenticator
$GA_KEY
" RATE_LIMIT 3 30
" WINDOW_SIZE 17
" TOTP_AUTH

EOF

    chown maintenance:maintenance /home/maintenance/.google_authenticator
    chmod 0600 /home/maintenance/.google_authenticator
}

alpine_generate_ssh_keys() {
    for KEY_TYPE in "ed25519" "dsa" "ecdsa" "rsa"; do
        echo "generating $KEY_TYPE ssh-keys"
        ssh-keygen -q -o -a 100 -t "$KEY_TYPE" -f /etc/ssh/ssh_host_"$KEY_TYPE"_key -N ""
    done
}

#============================  n e t w o r k i n g  ===========================#

alpine_setup_eth() {
    BUILD_HOSTNAME=$1
    cat <<EOF >>/etc/network/interfaces

auto eth0
iface eth0 inet dhcp
    hostname $BUILD_HOSTNAME

EOF
}

alpine_setup_wlan() {
    BUILD_HOSTNAME=$1
    SSID="$(cat "$DIR_ALPINE_SETUP"/secrets/wlan/ssid)"
    PASSWORD="$(cat "$DIR_ALPINE_SETUP"/secrets/wlan/password)"

    apk add wpa_supplicant
    rc-update add wpa_supplicant default

    wpa_passphrase "$SSID" "$PASSWORD" >/etc/wpa_supplicant/wpa_supplicant.conf

    # remove the clear password...
    sed -i '/^[[:blank:]]*#/d;s/#.*//' /etc/wpa_supplicant/wpa_supplicant.conf

    cat <<EOF >>/etc/network/interfaces
auto wlan0
iface wlan0 inet dhcp
    hostname $BUILD_HOSTNAME

EOF
}

#============================= a p k  c a c h e ===============================#

alpine_setup_apkcache_config() {
    ln -s /var/cache/apk /etc/apk/cache
}

alpine_setup_apkcache_sync() {
    # fetching all deps in the apk cache
    apk cache sync

    # move the cache var to where it will be mounted
    rm /etc/apk/cache
    ln -s /media/mmcblk0p2/var/cache/apk /etc/apk/cache

    # adding the first ext4 partition to the fstab, to have the var cache at startup
    echo "/dev/mmcblk0p2 /media/mmcblk0p2 ext4 rw,relatime 0 0" >>/etc/fstab
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
NETWORKING=$5

mkdir -p /etc
printf 'nameserver 8.8.8.8\nnameserver 2620:0:ccc::2' >/etc/resolv.conf

alpine_setup_apkcache_config
alpine_setup_hostname "$BUILD_HOSTNAME"
alpine_setup_repositories "$ALPINE_MIRROR" "$ALPINE_BRANCH"
alpine_setup_dns
alpine_setup_install_essentials
alpine_setup_keymap
alpine_setup_timezone "$TIMEZONE"
alpine_setup_networking
alpine_setup_reinstall_pkg_boot
alpine_setup_initd
alpine_setup_user
alpine_setup_ssh

# Check ../../../scripts/defaults for the different values
if test "$NETWORKING" = 1 || test "$NETWORKING" = 3; then
    alpine_setup_eth "$BUILD_HOSTNAME"
fi
if test "$NETWORKING" = 2 || test "$NETWORKING" = 3; then
    alpine_setup_wlan "$BUILD_HOSTNAME"
fi

alpine_setup_apkcache_sync
alpine_setup_lbu_commit
