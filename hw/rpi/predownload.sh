#!/usr/bin/env bash

set -Eeuo pipefail

#==============================================================================#

#============================== i n c l u d e s ===============================#

DIR_PREDL=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
if [[ ! -d "$DIR_PREDL" ]]; then DIR_PREDL="$PWD"; fi

mkdir -p "$DIR_PREDL/downloads"
wget http://dl-cdn.alpinelinux.org/alpine/v3.13/releases/aarch64/alpine-rpi-3.13.5-aarch64.tar.gz -O "$DIR_PREDL/downloads/alpine-rpi-3.13.5-aarch64.tar.gz" -q --show-progress
wget http://dl-cdn.alpinelinux.org/alpine/v3.13/releases/armhf/alpine-rpi-3.13.5-armhf.tar.gz -O "$DIR_PREDL/downloads/alpine-rpi-3.13.5-armhf.tar.gz" -q --show-progress
