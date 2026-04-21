#!/bin/bash
# Generates encryption keys for Kibana.
# See https://www.elastic.co/docs/reference/kibana/commands/kibana-encryption-keys

set -euo pipefail
IFS=$'\n\t'

cleanup() {
    rv=$?
    rm -rf "$tmpfile"
    exit $rv
}

trap "cleanup" EXIT

[ -f .env ] && source .env || { echo "$0: cannot find .env file" >&2; exit 1; }

KIBANA_IMAGE=docker.elastic.co/kibana/kibana:${STACK_VERSION}

tmpfile="$(mktemp)"

docker run --rm "$KIBANA_IMAGE" bin/kibana-encryption-keys generate | tee "$tmpfile"

echo -e "\e[1;92mDone. Make sure to add these values in .env file\e[0m"

grep '^xpack\.[a-zA-Z.]\+: [a-zA-Z0-9]\+$' "$tmpfile" | tr '.' '_' | sed 's/^xpack/KIBANA/' | sed 's/\([^A-Z]\+\)/\1_/g' | sed 's/_$//' | sed 's/^\([^:]\+\): /\U\1=/'
