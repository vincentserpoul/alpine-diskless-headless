#!/usr/bin/env sh

set -eu

#==============================================================================#

#===============================  e n v  v a r s  =============================#

# base config

: "${BASE_USERS_REMOTE_USER?Need to set the BASE_USERS_REMOTE_USER}"
: "${PROVISIONER_TWO_FACTOR_AUTH_SECRET?Need to set the PROVISIONER_TWO_FACTOR_AUTH_SECRET}"

#=============================== s s h ========================================#

provisioner_twofa() {
    BASE_USERS_REMOTE_USER=$1
    PROVISIONER_TWO_FACTOR_AUTH_SECRET=$2

    apk add openssh-server-pam google-authenticator

    mkdir -p /etc/pam.d
    echo "auth required pam_google_authenticator.so" >/etc/pam.d/sshd

    sed -i 's/#UsePAM no/UsePAM yes/' /etc/ssh/sshd_config

    GA_CONF="/home/$BASE_USERS_REMOTE_USER/.google_authenticator"

    cat <<EOF >>"$GA_CONF"
$PROVISIONER_TWO_FACTOR_AUTH_SECRET
" RATE_LIMIT 3 30
" WINDOW_SIZE 17
" DISALLOW_REUSE
" TOTP_AUTH

EOF

    chown "$BASE_USERS_REMOTE_USER":"$BASE_USERS_REMOTE_USER" "$GA_CONF"
    chmod 0600 "$GA_CONF"
}

#==============================================================================#

provisioner_twofa "$BASE_USERS_REMOTE_USER" "$PROVISIONER_TWO_FACTOR_AUTH_SECRET"
