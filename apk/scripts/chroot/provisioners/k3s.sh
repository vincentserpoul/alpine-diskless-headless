#!/usr/bin/env sh

set -eu

#==============================================================================#

#===============================  e n v  v a r s  =============================#

# user config
# PROVISIONER_K3S_TOKEN_VALUE: server token
: "${PROVISIONER_K3S_TOKEN_VALUE?Need to set PROVISIONER_K3S_TOKEN_VALUE}"
# PROVISIONER_K3S_K3S_ARGS: args for the k3s (agent or server)
: "${PROVISIONER_K3S_K3S_ARGS?Need to set PROVISIONER_K3S_K3S_ARGS}"
# PROVISIONER_K3S_TAINTS: taints for the k3s machine
: "${PROVISIONER_K3S_TAINTS?Need to set PROVISIONER_K3S_TAINTS}"
# PROVISIONER_K3S_LABELS: labels for the k3s machine
: "${PROVISIONER_K3S_LABELS?Need to set PROVISIONER_K3S_LABELS}"

#===================================  k 3 s  ==================================#

provisioner_k3s_install_pkg() {
    apk add k3s
}

#==============================================================================#

printf "\n> k3s setup\n"

privsioner_k3s_install_pkg
