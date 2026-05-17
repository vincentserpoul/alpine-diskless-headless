#! /bin/sh

profile_adh() {
    profile_rpi
    apks="$apks
        rsync sudo eudev avahi dbus ip6tables iptables
        "
}
