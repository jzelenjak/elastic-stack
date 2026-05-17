#!/bin/bash
# Helper wrapper script to simplify Docker Compose operations based on Elasticsearch mode (e.g. single-node vs multi-node cluster).

set -euo pipefail
IFS=$'\n\t'

usage() {
    cat << EOF
usage: $0 [MODE] COMPOSE_COMMAND [ARGS...]

MODE:
  single           [default] single-node Elasticsearch cluster
  multi            multi-node Elasticsearch cluster after bootstrap
  multi-bootstrap  first start for a new multi-node Elasticsearch cluster

EXAMPLES:
  $0 up
  $0 single up -d
  $0 multi config
  $0 multi-bootstrap config
EOF
}

COMPOSE_FILE_BASE="compose.yaml"
COMPOSE_FILE_MULTI_NODE="compose.multi-node.yaml"
COMPOSE_FILE_MULTI_NODE_BOOTSTRAP="compose.multi-node.bootstrap.yaml"

[[ $# -eq 0 ]] && { usage >&2 ; exit 1; }

ARGS=("-f" "$COMPOSE_FILE_BASE")
case "${1:-}" in
    multi)
	    ARGS+=("-f" "$COMPOSE_FILE_MULTI_NODE")
        shift
        ;;
    multi-bootstrap)
	    ARGS+=("-f" "$COMPOSE_FILE_MULTI_NODE" "-f" "$COMPOSE_FILE_MULTI_NODE_BOOTSTRAP")
        shift
        ;;
    single)
        shift
        ;;
    help|--help|-h)
        usage
        exit 0
        ;;
esac
ARGS+=("$@")

exec docker compose "${ARGS[@]}"
