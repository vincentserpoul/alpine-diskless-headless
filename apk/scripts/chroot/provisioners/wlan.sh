#!/usr/bin/env sh

set -eu

#==============================================================================#

#===============================  e n v  v a r s  =============================#

# user config

# PROVISIONER_WLAN_SSID: ssid of the wlan
: "${PROVISIONER_WLAN_SSID?Need to set PROVISIONER_WLAN_SSID}"

# PROVISIONER_WLAN_PASSWORD: password of the wlan
: "${PROVISIONER_WLAN_PASSWORD?Need to set PROVISIONER_WLAN_PASSWORD}"

# base config
: "${BASE_HOSTNAME?Need to set BASE_HOSTNAME}"

#==============================  e t h e r n e t  ============================#

provisioner_wlan() {
    BASE_HOSTNAME=$1
    PROVISIONER_WLAN_SSID=$2
    PROVISIONER_WLAN_PASSWORD=$3

    apk add wpa_supplicant
    rc-update add wpa_supplicant default

    wpa_passphrase "$PROVISIONER_WLAN_SSID" "$PROVISIONER_WLAN_PASSWORD" >/etc/wpa_supplicant/wpa_supplicant.conf

    # remove the clear password...
    sed -i '/^[[:blank:]]*#/d;s/#.*//' /etc/wpa_supplicant/wpa_supplicant.conf

    cat <<EOF >>/etc/network/interfaces
auto wlan0
iface wlan0 inet dhcp
    hostname $BASE_HOSTNAME

EOF
}

#==============================================================================#

provisioner_wlan "$BASE_HOSTNAME" "$PROVISIONER_WLAN_SSID" "$PROVISIONER_WLAN_PASSWORD"
