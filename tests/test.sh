#!/usr/bin/env bash

set -uo pipefail

DIR_TEST="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_TEST" ]]; then DIR_TEST="$PWD"; fi

# shellcheck source=/dev/null
. """$DIR_TEST""/../scripts/utils.sh"

PROVISIONER=$1

: "${PROVISIONER?Need to set the provisioner as a param (test.sh ethernet)}"

# Run provisioner inside alpine container
docker run -dit --name test-"$PROVISIONER" \
    --mount type=bind,source="$(pwd)"/apk/scripts/chroot/provisioners,target=/provisioners,readonly \
    --mount type=bind,source="$(pwd)"/tests/apk/scripts/chroot/provisioners,target=/tests/provisioners,readonly \
    --env-file "$(pwd)"/tests/apk/scripts/chroot/provisioners/"$PROVISIONER".env \
    vincentserpoul/alpine-diskless-headless-test /bin/sh

# Run provisioner
docker exec -it test-"$PROVISIONER" /bin/sh -c "/provisioners/$PROVISIONER.sh" || ewarn "$PROVISIONER failed"

# Run test provisioner
docker exec -it test-"$PROVISIONER" /bin/sh -c "/tests/provisioners/$PROVISIONER.sh" || ewarn "$PROVISIONER test failed"

# remove
einfo "removing test container"
docker stop test-"$PROVISIONER" && docker rm test-"$PROVISIONER"
