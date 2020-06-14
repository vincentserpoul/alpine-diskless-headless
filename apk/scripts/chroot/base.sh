#!/usr/bin/env sh

set -eu

#==============================================================================#

#==============================  a p k  c a c h e  ============================#

alpine_setup_apkcache_config() {
    ln -s /var/cache/apk /etc/apk/cache
}

#===============================  h o s t n a m e  ============================#

#===============================  e n v  v a r s  =============================#

: "${BASE_HOSTNAME?Need to set BASE_HOSTNAME}"

#==============================================================================#

alpine_setup_hostname() {
    BASE_HOSTNAME=$1

    setup-hostname -n "$BASE_HOSTNAME"
    hostname "$BASE_HOSTNAME"

    printf "Welcome to %s!\n\n" "$BASE_HOSTNAME" >/etc/motd
}

#============================  r e p o s i t o r i e s  =======================#

#===============================  e n v  v a r s  =============================#

: "${BASE_ALPINE_MIRROR?Need to set BASE_ALPINE_MIRROR (http:\/\/dl-cdn.alpinelinux.org\/alpine...)}"
: "${BASE_ALPINE_BRANCH?Need to set BASE_ALPINE_BRANCH (latest-stable...)}"

#==============================================================================#

alpine_setup_repositories() {
    BASE_ALPINE_MIRROR=$1
    BASE_ALPINE_BRANCH=$2

    mkdir -p /etc/apk
    printf '%s\n' \
        "$BASE_ALPINE_MIRROR/$BASE_ALPINE_BRANCH/main" \
        "$BASE_ALPINE_MIRROR/$BASE_ALPINE_BRANCH/community" \
        >/etc/apk/repositories

    setup-apkrepos -1
}

#===================================  d n s  ==================================#

#===============================  e n v  v a r s  =============================#

: "${BASE_NETWORKING_DNS_NAMESERVERS?Need to set BASE_NETWORKING_DNS_NAMESERVERS (8.8.8.8 1.1.1.1 ...)}"

#==============================================================================#

alpine_setup_dns() {
    ALL_DNS=$1

    rm /etc/resolv.conf
    touch /etc/resolv.conf

    #Print the split string
    DELIMITER=", "
    while test "${ALL_DNS#*$DELIMITER}" != "$ALL_DNS"; do
        echo "nameserver ${ALL_DNS%%$DELIMITER*}" >>/etc/resolv.conf
        ALL_DNS="${ALL_DNS#*$DELIMITER}"
    done
    echo "nameserver $ALL_DNS" >>/etc/resolv.conf
}

#=================================  k e y m a p  ==============================#

#===============================  e n v  v a r s  =============================#

: "${BASE_ALPINE_KEYMAP?Need to set BASE_ALPINE_KEYMAP (us us...)}"

#==============================================================================#

alpine_setup_keymap() {
    BASE_ALPINE_KEYMAP=$1

    LAYOUT="${BASE_ALPINE_KEYMAP% *}"
    VARIANT="${BASE_ALPINE_KEYMAP#* }"

    setup-keymap "$LAYOUT" "$VARIANT"
}

#=============================  f u n c t i o n s  ============================#

#===============================  e n v  v a r s  =============================#

: "${BASE_ALPINE_TIMEZONE?Need to set BASE_ALPINE_TIMEZONE (Asia\/Singapore)}"

#==============================================================================#

alpine_setup_timezone() {
    BASE_ALPINE_TIMEZONE=$1

    setup-timezone -z "$BASE_ALPINE_TIMEZONE"
}

#==============================  n e t w o r k i n g  =========================#

alpine_setup_networking() {
    cat <<EOF >/etc/network/interfaces
auto lo
iface lo inet loopback

EOF
}

#====================================  u s e r  ===============================#

: "${BASE_USERS_ROOT_PASSWORD?Need to set BASE_USERS_ROOT_PASSWORD}"
: "${BASE_USERS_REMOTE_USER?Need to set BASE_USERS_REMOTE_USER}"
: "${BASE_USERS_REMOTE_USER_PASSWORD?Need to set BASE_USERS_REMOTE_USER_PASSWORD}"

alpine_setup_user() {
    BASE_USERS_ROOT_PASSWORD=$1
    BASE_USERS_REMOTE_USER=$2
    BASE_USERS_REMOTE_USER_PASSWORD=$3

    alpine_change_pass root "$BASE_USERS_ROOT_PASSWORD"

    /usr/sbin/addgroup -S "$BASE_USERS_REMOTE_USER"
    /usr/sbin/adduser "$BASE_USERS_REMOTE_USER" --ingroup "$BASE_USERS_REMOTE_USER" --disabled-password --shell /bin/ash

    mkdir -p /home/"$BASE_USERS_REMOTE_USER"

    alpine_change_pass "$BASE_USERS_REMOTE_USER" "$BASE_USERS_REMOTE_USER_PASSWORD"

    alpine_sudoers "$BASE_USERS_REMOTE_USER"

    # adding home to lbu
    lbu add /home/"$BASE_USERS_REMOTE_USER" "$BASE_USERS_REMOTE_USER"
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

: "${BASE_SSH_AUTHORIZED_KEYS?Need to set BASE_SSH_AUTHORIZED_KEYS}"

#=============================== s s h ========================================#

alpine_setup_ssh() {
    BASE_SSH_AUTHORIZED_KEYS=$1
    BASE_USERS_REMOTE_USER=$2

    sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#LogLevel INFO/LogLevel INFO/' /etc/ssh/sshd_config
    sed -i 's/#ListenAddress ::/ListenAddress ::/' /etc/ssh/sshd_config
    sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config

    cat <<EOF >>/etc/ssh/sshd_config

AuthenticationMethods publickey,keyboard-interactive
AllowUsers $BASE_USERS_REMOTE_USER

EOF

    # copy ssh keys
    mkdir -p /home/"$BASE_USERS_REMOTE_USER"/.ssh
    #Print the split string
    DELIMITER=", "
    while test "${BASE_SSH_AUTHORIZED_KEYS#*$DELIMITER}" != "$BASE_SSH_AUTHORIZED_KEYS"; do
        echo "${BASE_SSH_AUTHORIZED_KEYS%%$DELIMITER*}" >>/home/"$BASE_USERS_REMOTE_USER"/.ssh/authorized_keys
        BASE_SSH_AUTHORIZED_KEYS="${BASE_SSH_AUTHORIZED_KEYS#*$DELIMITER}"
    done
    echo "$BASE_SSH_AUTHORIZED_KEYS" >>/home/"$BASE_USERS_REMOTE_USER"/.ssh/authorized_keys

    # generate local ssh keys
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
alpine_setup_hostname "$BASE_HOSTNAME"
alpine_setup_repositories "$BASE_ALPINE_MIRROR" "$BASE_ALPINE_BRANCH"
alpine_setup_dns "$BASE_NETWORKING_DNS_NAMESERVERS"
alpine_setup_install_essentials
alpine_setup_keymap "$BASE_ALPINE_KEYMAP"
alpine_setup_timezone "$BASE_ALPINE_TIMEZONE"
alpine_setup_networking
alpine_setup_reinstall_pkg_boot
alpine_setup_initd
alpine_setup_user "$BASE_USERS_ROOT_PASSWORD" "$BASE_USERS_REMOTE_USER" "$BASE_USERS_REMOTE_USER_PASSWORD"
alpine_setup_ssh "$BASE_SSH_AUTHORIZED_KEYS" "$BASE_USERS_REMOTE_USER"
