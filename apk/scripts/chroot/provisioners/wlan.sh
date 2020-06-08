#!/usr/bin/env sh

set -eu

#==============================================================================#

#===============================  e n v  v a r s  =============================#

: "${BUILD_HOSTNAME?Need to set BUILD_HOSTNAME}"
: "${WLAN_SSID?Need to set WLAN_SSID}"
: "${WLAN_PASSWORD?Need to set WLAN_PASSWORD}"

#==============================  e t h e r n e t  ============================#

alpine_setup_wlan() {
    BUILD_HOSTNAME=$1
    WLAN_SSID=$2
    WLAN_PASSWORD=$3

    apk add wpa_supplicant
    rc-update add wpa_supplicant default

    wpa_passphrase "$WLAN_SSID" "$WLAN_PASSWORD" >/etc/wpa_supplicant/wpa_supplicant.conf

    # remove the clear password...
    sed -i '/^[[:blank:]]*#/d;s/#.*//' /etc/wpa_supplicant/wpa_supplicant.conf

    cat <<EOF >>/etc/network/interfaces
auto wlan0
iface wlan0 inet dhcp
    hostname $BUILD_HOSTNAME

EOF
}

#==============================================================================#

printf "\n> wlan setup\n"

alpine_setup_wlan "$BUILD_HOSTNAME" "$WLAN_SSID" "$WLAN_PASSWORD"
