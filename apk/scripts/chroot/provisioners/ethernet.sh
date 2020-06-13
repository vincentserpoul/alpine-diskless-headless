#!/usr/bin/env sh

set -eu

#==============================================================================#

#===============================  e n v  v a r s  =============================#

# base config

# hostname
: "${BASE_HOSTNAME?Need to set BASE_HOSTNAME}"

#==============================  e t h e r n e t  ============================#

provisioner_ethernet() {
    BASE_HOSTNAME=$1
    cat <<EOF >>/etc/network/interfaces

auto eth0
iface eth0 inet dhcp
    hostname $BASE_HOSTNAME

EOF
}

#==============================================================================#

provisioner_ethernet "$BASE_HOSTNAME"
