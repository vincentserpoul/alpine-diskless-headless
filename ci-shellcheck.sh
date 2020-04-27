#!/usr/bin/env bash

set -euo pipefail

for f in $(
    {
        find . -type f -regex ".*\.\w*sh"
        file ./* | grep 'shell script' | cut -d: -f1
    } | sort -u
); do
    shellcheck "$f"
done
