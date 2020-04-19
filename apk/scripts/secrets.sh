#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_APK_TOOLS="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_APK_TOOLS" ]]; then DIR_APK_TOOLS="$PWD"; fi

. """$DIR_APK_TOOLS""/../../scripts/utils.sh"

#================================= s e c r e t s ==============================#

secrets-user-root-password() {
    local ROOT_PASSWORD

    local -r FILE_DIR="$DIR_APK_TOOLS"/../secrets/users
    local -r FILE_PATH="$FILE_DIR"/root.password

    if [ ! -f "$FILE_PATH" ]; then
        mkdir -p "$FILE_DIR"
        read -r -s -p "root password:" ROOT_PASSWORD
        echo "$ROOT_PASSWORD" >"$FILE_PATH"
        echo
    fi
}

secrets-user-maintenance-password() {
    local MAINTENANCE_PASSWORD

    local -r FILE_DIR="$DIR_APK_TOOLS"/../secrets/users
    local -r FILE_PATH="$FILE_DIR"/maintenance.password

    if [ ! -f "$FILE_PATH" ]; then
        mkdir -p "$FILE_DIR"
        read -r -s -p "maintenance password:" MAINTENANCE_PASSWORD
        echo "$MAINTENANCE_PASSWORD" >"$FILE_PATH"
        echo
    fi
}

#TODO multi line
secrets-ssh-authorized_keys() {
    local AUTHORIZED_KEYS

    local -r FILE_DIR="$DIR_APK_TOOLS"/../secrets/ssh
    local -r FILE_PATH="$FILE_DIR"/authorized_keys

    if [ ! -f "$FILE_PATH" ]; then
        mkdir -p "$FILE_DIR"
        read -r -s -p "ssh authorized key (one):" AUTHORIZED_KEYS
        echo "$AUTHORIZED_KEYS" >"$FILE_PATH"
        echo
    fi
}

secrets-2fa() {
    local TWOFA

    local -r FILE_DIR="$DIR_APK_TOOLS"/../secrets/2fa
    local -r FILE_PATH="$FILE_DIR"/google_authenticator

    if [ ! -f "$FILE_PATH" ]; then
        mkdir -p "$FILE_DIR"
        read -r -s -p "2fa code:" TWOFA
        echo "$TWOFA" >"$FILE_PATH"
        echo
    fi
}

secrets-wlan() {
    local WLAN_SSID
    local WLAN_PSK

    local -r FILE_DIR="$DIR_APK_TOOLS"/../secrets/wlan
    local -r FILE_PATH_SSID="$FILE_DIR"/ssid
    local -r FILE_PATH_PSK="$FILE_DIR"/psk

    if [ ! -f "$FILE_PATH_SSID" ]; then
        mkdir -p "$FILE_DIR"
        read -r -s -p "wlan ssid:" WLAN_SSID
        echo "$WLAN_SSID" >"$FILE_PATH_SSID"
        echo
    fi

    if [ ! -f "$FILE_PATH_PSK" ]; then
        mkdir -p "$FILE_DIR"
        read -r -s -p "wlan psk:" WLAN_PSK
        echo "$WLAN_PSK" >"$FILE_PATH_PSK"
        echo
    fi
}

#================================= s e c r e t s ==============================#

secrets() {
    secrets-user-root-password
    secrets-user-maintenance-password
    secrets-ssh-authorized_keys
    secrets-2fa
    secrets-wlan
}
