#!/usr/bin/env sh

set -eu

#=================================== l b u ====================================#

alpine_setup_lbu_commit() {
    mkdir -p /config
    lbu pkg /config/alpine.apkovl.tar.gz
}

alpine_setup_apkcache_sync() {
    # fetching all deps in the apk cache
    apk cache sync

    # move the cache var to where it will be mounted
    rm /etc/apk/cache
    ln -s /media/mmcblk0p2/var/cache/apk /etc/apk/cache

    # adding the first ext4 partition to the fstab, to have the var cache at startup
    echo "/dev/mmcblk0p2 /media/mmcblk0p2 ext4 rw,relatime 0 0" >>/etc/fstab

    tar czf \
        /config/alpine.apkcache.tar.gz \
        -C /var/cache/apk \
        .
}

#==============================================================================#

printf "\n> save in cache and commit in lbu\n"

alpine_setup_apkcache_sync
alpine_setup_lbu_commit
