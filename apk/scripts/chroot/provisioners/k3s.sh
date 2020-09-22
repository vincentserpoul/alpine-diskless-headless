#!/usr/bin/env sh

set -eu

#==============================================================================#

#===============================  e n v  v a r s  =============================#

# user config
# PROVISIONER_K3S_TOKEN_VALUE: server token
: "${PROVISIONER_K3S_TOKEN_VALUE?Need to set PROVISIONER_K3S_TOKEN_VALUE}"
# PROVISIONER_K3S_K3S_ARGS: args for the k3s (agent or server)
: "${PROVISIONER_K3S_EXEC?Need to set PROVISIONER_K3S_EXEC}"
# PROVISIONER_K3S_DATA_DIR: datadir
: "${PROVISIONER_K3S_DATA_DIR?Need to set PROVISIONER_K3S_DATA_DIR}"

#===================================  k 3 s  ==================================#

provisioner_k3s_install_pkg() {
    apk add curl

    curl -sfL https://get.k3s.io |
        INSTALL_K3S_EXEC="$PROVISIONER_K3S_EXEC" \
            sh -s - \
            --token "$PROVISIONER_K3S_TOKEN_VALUE" \
            --node-name "$BASE_HOSTNAME" \
            --node-label "$BASE_ARCH" \
            --data-dir "$PROVISIONER_K3S_DATA_DIR" || true

    lbu add "$PROVISIONER_K3S_DATA_DIR"

}

#==============================================================================#

printf "\n> k3s setup\n"

provisioner_k3s_install_pkg
