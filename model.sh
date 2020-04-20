#!/usr/bin/env bash

set -euo pipefail

# ONLY RUN THIS WHEN THE RUN is not giving a proper result

DIR_BASE="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_BASE" ]]; then DIR_BASE="$PWD"; fi

. """$DIR_BASE""/scripts/utils.sh"
. """$DIR_BASE""/scripts/defaults.sh"
. """$DIR_BASE""/scripts/helpers.sh"
. """$DIR_BASE""/scripts/dev.sh"

mkdir -p /mnt/sda2
mount /dev/sda2 /mnt/sda2
cp "$DIR_BASE"/apk/scripts/alpine-setup-local.sh /mnt/sda2/
cp -r "$DIR_BASE"/apk/secrets /mnt/sda2/

umount /dev/sda2
