#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

#============================  L o g g i n g  =================================#

die() {
	printf '\033[1;31mERROR:\033[0m %s\n' "$@" >&2 # bold red
	exit 1
}

einfo() {
	printf '\n\033[1;36m> %s\033[0m\n' "$@" >&2 # bold cyan
}

ewarn() {
	printf '\033[1;33m> %s\033[0m\n' "$@" >&2 # bold yellow
}

usage() {
	sed -En '/^#---help---/,/^#---help---/p' "$0" | sed -E 's/^# ?//; 1d;$d;'
}

#================================  C h e c k  =================================#

dep-check() {
	local -r EXEC_CHECK=$1

	hash "$EXEC_CHECK" 2>/dev/null ||
		die "$EXEC_CHECK is required but it's not present. Aborting."
}

root-check() {
	if [ "$(id -u)" -ne 0 ]; then
		die 'This script must be run as root!'
	fi
}

#=================================  S o u r c e ===============================#

source-folder() {
	local -r SOURCE_FOLDER=$1

	eval "$(find "$SOURCE_FOLDER" -maxdepth 1 -type f -exec echo . \'{}\'';' \;)"
}
