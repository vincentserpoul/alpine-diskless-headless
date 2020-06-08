#!/usr/bin/env sh

set -eu

#==============================================================================#

#==============================  a p k  c a c h e  ============================#

alpine_setup_apkcache_config() {
    ln -s /var/cache/apk /etc/apk/cache
}

#===============================  h o s t n a m e  ============================#

#===============================  e n v  v a r s  =============================#

: "${BUILD_HOSTNAME?Need to set BUILD_HOSTNAME}"

#==============================================================================#

alpine_setup_hostname() {
    BUILD_HOSTNAME=$1

    setup-hostname -n "$BUILD_HOSTNAME"
    hostname "$BUILD_HOSTNAME"

    printf "Welcome to %s!\n\n" "$BUILD_HOSTNAME" >/etc/motd
}

#============================  r e p o s i t o r i e s  =======================#

#===============================  e n v  v a r s  =============================#

: "${ALPINE_MIRROR?Need to set ALPINE_MIRROR (http:\/\/dl-cdn.alpinelinux.org\/alpine...)}"
: "${ALPINE_BRANCH?Need to set ALPINE_BRANCH (latest-stable...)}"

#==============================================================================#

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

#===================================  d n s  ==================================#

#===============================  e n v  v a r s  =============================#

: "${DNS?Need to set DNS (8.8.8.8 1.1.1.1 ...)}"

#==============================================================================#

alpine_setup_dns() {
    DNS=$1

    setup-dns -d "none" -n "$DNS"
}

#=================================  k e y m a p  ==============================#

#===============================  e n v  v a r s  =============================#

: "${KEYMAP?Need to set KEYMAP (us us...)}"

#==============================================================================#

alpine_setup_keymap() {
    KEYMAP=$1

    LAYOUT="${KEYMAP% *}"
    VARIANT="${KEYMAP#* }"

    setup-keymap "$LAYOUT" "$VARIANT"
}

#=============================  f u n c t i o n s  ============================#

#===============================  e n v  v a r s  =============================#

: "${TIMEZONE?Need to set TIMEZONE (Asia\/Singapore)}"

#==============================================================================#

alpine_setup_timezone() {
    TIMEZONE=$1

    setup-timezone -z "$TIMEZONE"
}

#==============================  n e t w o r k i n g  =========================#

alpine_setup_networking() {
    cat <<EOF >/etc/network/interfaces
auto lo
iface lo inet loopback

EOF
}

#====================================  u s e r  ===============================#

: "${ROOT_PASSWORD?Need to set ROOT_PASSWORD}"
: "${REMOTE_USER?Need to set REMOTE_USER}"
: "${REMOTE_USER_PASSWORD?Need to set REMOTE_USER_PASSWORD}"

alpine_setup_user() {
    ROOT_PASSWORD=$1
    REMOTE_USER=$2
    REMOTE_USER_PASSWORD=$3

    alpine_change_pass root "$ROOT_PASSWORD"

    /usr/sbin/addgroup -S "$REMOTE_USER"
    /usr/sbin/adduser "$REMOTE_USER" --ingroup "$REMOTE_USER" --disabled-password --shell /bin/ash

    mkdir -p /home/"$REMOTE_USER"

    alpine_change_pass "$REMOTE_USER" "$REMOTE_USER_PASSWORD"

    alpine_sudoers "$REMOTE_USER"

    # adding home to lbu
    lbu add /home/"$REMOTE_USER" "$REMOTE_USER"
}

alpine_change_pass() {
    USER=$1
    PASSWORD=$2

    echo "$USER":"$PASSWORD" | /usr/sbin/chpasswd
}

alpine_sudoers() {
    USER=$1
    GROUP=$1

    echo "%""$GROUP"" ALL=(ALL) ALL" >/etc/sudoers.d/"$USER"
}

#==============================================================================#

#===============================  e n v  v a r s  =============================#

: "${AUTHORIZED_KEYS?Need to set AUTHORIZED_KEYS}"

#=============================== s s h ========================================#

alpine_setup_ssh() {
    AUTHORIZED_KEYS=$1
    REMOTE_USER=$2

    sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#LogLevel INFO/LogLevel INFO/' /etc/ssh/sshd_config
    sed -i 's/#ListenAddress ::/ListenAddress ::/' /etc/ssh/sshd_config
    sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config

    cat <<EOF >>/etc/ssh/sshd_config

AuthenticationMethods publickey,keyboard-interactive
AllowUsers $REMOTE_USER

EOF

    # copy ssh keys
    mkdir -p /home/"$REMOTE_USER"/.ssh
    #Print the split string
    for AK in $AUTHORIZED_KEYS; do
        echo "$AK" >/home/"$REMOTE_USER"/.ssh/authorized_keys
    done

    # generate ssh keys - NOT WORKING YET
    alpine_generate_ssh_keys
}

alpine_generate_ssh_keys() {
    for KEY_TYPE in "ed25519" "dsa" "ecdsa" "rsa"; do
        echo "generating $KEY_TYPE ssh-keys"
        ssh-keygen -q -o -a 100 -t "$KEY_TYPE" -f /etc/ssh/ssh_host_"$KEY_TYPE"_key -N ""
    done
}

#===================================  c o r e  ================================#

alpine_setup_reinstall_pkg_boot() {
    cat <<EOF >/etc/init.d/reinstall-pkg
#!/sbin/openrc-run

description="Install necessary packages at boot"

depend() {
  after modules
  need localmount
}

start() {
    /sbin/apk fix --no-network
}
EOF

    chmod +x /etc/init.d/reinstall-pkg
    lbu include /etc/init.d/reinstall-pkg
}

alpine_setup_install_essentials() {
    apk update

    apk add \
        openssh rsync sudo eudev haveged chrony avahi dbus tzdata

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

#==================================  m a i n  =================================#

printf "\n> base setup\n"

mkdir -p /etc
printf 'nameserver 8.8.8.8\nnameserver 2620:0:ccc::2' >/etc/resolv.conf

alpine_setup_apkcache_config
alpine_setup_hostname "$BUILD_HOSTNAME"
alpine_setup_repositories "$ALPINE_MIRROR" "$ALPINE_BRANCH"
alpine_setup_dns "$DNS"
alpine_setup_install_essentials
alpine_setup_keymap "$KEYMAP"
alpine_setup_timezone "$TIMEZONE"
alpine_setup_networking
alpine_setup_reinstall_pkg_boot
alpine_setup_initd
alpine_setup_user "$ROOT_PASSWORD" "$REMOTE_USER" "$REMOTE_USER_PASSWORD"
alpine_setup_ssh "$AUTHORIZED_KEYS" "$REMOTE_USER"
