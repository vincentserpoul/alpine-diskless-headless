#!/usr/bin/env sh

set -eu

grep -c "iface eth0 inet dhcp" </etc/network/interfaces
