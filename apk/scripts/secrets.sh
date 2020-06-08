#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_SECRETS="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_SECRETS" ]]; then DIR_SECRETS="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_SECRETS""/../../scripts/utils.sh"

#================================= s e c r e t s ==============================#

secret() {
    local -r CATEGORY=$1
    local -r KEY=$2
    local -r DESCRIPTION=$3

    local -r FILE_DIR="$DIR_SECRETS"/../secrets/"$CATEGORY"
    local -r FILE_PATH="$FILE_DIR"/"$KEY"

    local SECRET_DATA

    if [ ! -f "$FILE_PATH" ]; then
        mkdir -p "$FILE_DIR"
        read -r -s -p "$DESCRIPTION: " SECRET_DATA
        echo "$SECRET_DATA" >"$FILE_PATH"
        echo
    fi
}

#================================= s e c r e t s ==============================#

secrets() {
    secret "users" "root.password" "root password"
    secret "users" "maintenance.password" "maintenance password"

    secret "wlan" "ssid" "wifi network ssid"
    secret "wlan" "password" "wifi password"
}

get_secret() {
    local -r CATEGORY=$1
    local -r KEY=$2

    local -r FILE_DIR="$DIR_SECRETS"/../secrets/"$CATEGORY"
    local -r FILE_PATH="$FILE_DIR"/"$KEY"

    cat "$FILE_PATH"
}
