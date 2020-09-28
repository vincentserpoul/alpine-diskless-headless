#!/usr/bin/env sh

set -eu

#==============================================================================#

#===============================  e n v  v a r s  =============================#

# user config
: "${PROVISIONER_K3S_EXEC?Need to set PROVISIONER_K3S_EXEC}"

# edge
# : "${PROVISIONER_K3S_EXEC_EDGE?Need to set PROVISIONER_K3S_EXEC}"
# : "${PROVISIONER_K3S_OPTS_EDGE?Need to set PROVISIONER_K3S_OPTS}"

#===================================  k 3 s  ==================================#

provisioner_k3s_install_pkg() {
    apk add curl

    curl -sfL https://get.k3s.io |
        INSTALL_K3S_EXEC="$BASE_HOSTNAME $PROVISIONER_K3S_EXEC" \
            sh -s - || true

    lbu add /usr/local/bin/k3s

    lbu add /usr/local/bin/kubectl
    lbu add /usr/local/bin/crictl
    lbu add /usr/local/bin/ctr
    lbu add /usr/local/bin/k3s-killall.sh
    lbu add /usr/local/bin/k3s-test-uninstall.sh

    lbu add /etc/rancher
    lbu add /etc/init.d/k3s-"$BASE_HOSTNAME"
}

provisioner_k3s_install_pkg_edge() {
    # shellcheck disable=SC2034
    K3S_EXEC=$PROVISIONER_K3S_EXEC_EDGE
    # shellcheck disable=SC2034
    K3S_OPTS=$PROVISIONER_K3S_OPTS_EDGE

    apk add -X http://dl-cdn.alpinelinux.org/alpine/edge/community \
        cni-plugins

    apk add -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        k3s

    rc-update add k3s default
}

#==============================================================================#

printf "\n> k3s setup\n"

provisioner_k3s_install_pkg
