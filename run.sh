#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

readonly VERSION="0.1.0"

#============================== i n c l u d e s ===============================#

DIR_BASE="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_BASE" ]]; then DIR_BASE="$PWD"; fi

. """$DIR_BASE""/scripts/utils.sh"
. """$DIR_BASE""/scripts/defaults.sh"
. """$DIR_BASE""/scripts/helpers.sh"
. """$DIR_BASE""/scripts/dev.sh"

#================================= m a i n ====================================#

while getopts 'd:a:m:b:v:p:n:t:fh' OPTION; do
	case "$OPTION" in
	d) HARDWARE="$OPTARG" ;;
	a) ARCH="$OPTARG" ;;
	m) ALPINE_MIRROR="$OPTARG" ;;
	b) ALPINE_BRANCH="$OPTARG" ;;
	v) ALPINE_VERSION="$OPTARG" ;;
	p) DEVICE_NAME="$OPTARG" ;;
	n) BUILD_HOSTNAME="$OPTARG" ;;
	t) TIMEZONE="$OPTARG" ;;
	f) FORCE=true ;;
	h)
		echo "alpine-diskless-headless-build $VERSION"
		exit 0
		;;
	*)
		echo "unknown flag"
		exit 0
		;;
	esac
done

root-check
helpers-build-hostname-check

einfo "running alpine-diskless-headless-build"

# apk
"$DIR_BASE"/apk/build.sh \
	-a "$ARCH" \
	-m "$ALPINE_MIRROR" \
	-b "$ALPINE_BRANCH" \
	-v "$ALPINE_VERSION" \
	-n "$BUILD_HOSTNAME" \
	-t "$TIMEZONE"

# hardware boot
"$DIR_BASE"/"$HARDWARE"/build.sh \
	-a "$ARCH" \
	-m "$ALPINE_MIRROR" \
	-b "$ALPINE_BRANCH" \
	-v "$ALPINE_VERSION"

# /dev/sda partition, mount, copy files, umount
if [ "$FORCE" == false ]; then
	echo
	read -p "Are you sure you want to format ""$DEVICE_NAME"" (Y/y)?" -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		die "script stopped by user"
	fi
fi

dev-partition-full "$DEVICE_NAME"

readonly BOOT_MOUNT_POINT="$(dev-boot-mount "$DEVICE_NAME")"
einfo "copying boot files and local backup to boot partition"
tar xzf "$(helpers-hardware-filepath-get "$HARDWARE" "$ARCH" "$ALPINE_VERSION")" --no-same-owner -C "$BOOT_MOUNT_POINT"
cp "$(helpers-apkovl-filepath-get "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME")" "$BOOT_MOUNT_POINT"
dev-boot-umount "$DEVICE_NAME"

readonly DISK_MOUNT_POINT="$(dev-disk-mount "$DEVICE_NAME")"
einfo "extracting apk cache to main ext4 partition"
tar xzf "$(helpers-apkcache-filepath-get "$ARCH" "$ALPINE_VERSION" "$BUILD_HOSTNAME")" --no-same-owner -C "$DISK_MOUNT_POINT"
dev-disk-umount "$DEVICE_NAME"
