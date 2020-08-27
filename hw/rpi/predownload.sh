#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_PREDL="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_PREDL" ]]; then DIR_PREDL="$PWD"; fi

mkdir -p "$DIR_PREDL/downloads"
wget http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/alpine-rpi-3.12.0-aarch64.tar.gz -O "$DIR_PREDL/downloads/alpine-rpi-3.12.0-aarch64.tar.gz" -q --show-progress
wget http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/armhf/alpine-rpi-3.12.0-armhf.tar.gz -O "$DIR_PREDL/downloads/alpine-rpi-3.12.0-armhf.tar.gz" -q --show-progress
