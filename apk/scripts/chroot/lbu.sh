#!/usr/bin/env sh

set -eu

#=================================== l b u ====================================#

alpine_setup_lbu_commit() {
    mkdir -p /target/
    lbu pkg /target/alpine.apkovl.tar.gz
}

#==============================================================================#

printf "\n> commit in lbu\n"

alpine_setup_lbu_commit
