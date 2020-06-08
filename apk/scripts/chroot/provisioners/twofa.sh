#!/usr/bin/env sh

set -eu

#==============================================================================#

#===============================  e n v  v a r s  =============================#

: "${REMOTE_USER?Need to set the REMOTE_USER}"

#=============================== s s h ========================================#

alpine_setup_ssh_2fa() {
    REMOTE_USER=$1

    apk add openssh-server-pam google-authenticator

    mkdir -p /etc/pam.d
    echo "auth required pam_google_authenticator.so" >/etc/pam.d/sshd

    sed -i 's/#UsePAM no/UsePAM yes/' /etc/ssh/sshd_config

    GA_KEY_SECRET_PATH="/secrets/2fa/google_authenticator"
    GA_CONF="/home/$REMOTE_USER/.google_authenticator"

    # In case there is no existing google auth
    if test ! -f "$GA_KEY_SECRET_PATH"; then
        apk add libqrencode

        echo
        echo "Generating the two factor code to connect to your device"
        echo

        echo "synchronizing time..."
        /usr/sbin/chronyd -s
        su -c google-authenticator "$REMOTE_USER" <<-EOF
y
-1
y
y
y
y
EOF
        apk del libqrencode
        echo
        echo "<Press any key> once you have scanned the QR Code with authy/google authenticator/... and saved your codes somewhere safe?"
        read -r _
    else
        cat "$GA_KEY_SECRET_PATH" >"$GA_CONF"
        chown "$REMOTE_USER":"$REMOTE_USER" "$GA_CONF"
        chmod 0600 "$GA_CONF"
    fi
}

#==============================================================================#

printf "\n> two factor auth setup\n"

alpine_setup_ssh_2fa "$REMOTE_USER"
