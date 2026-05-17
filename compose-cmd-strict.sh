#!/bin/bash
# Helper wrapper script to simplify Docker Compose operations based on Elasticsearch mode (e.g. single-node vs multi-node cluster).
# It is analogous to the `compose-cmd.sh` script, but it performs an extra check for startup Compose commands when using multi-node setup.

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

# Derives Compose project name based on current configuration
get_compose_project_name() {
    local compose_file_args=("$@")
    local project_name

    if command -v jq >/dev/null 2>&1; then
        project_name="$(docker compose "${compose_file_args[@]}" config --format json | jq -r '.name')"
    else
        project_name="$(docker compose "${compose_file_args[@]}" config --format json | 
            sed -n 's/^[[:space:]]*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*$/\1/p' | 
            head -1)"
    fi

    if [ -z "$project_name" ] || [ "$project_name" = "null" ]; then
        echo "$0: failed to derive Compose project name" >&2
        exit 1
    fi
    printf "%s\n" "$project_name"
}

# Checks if any data volumes exist for the specified ES nodes (within the specified Compose project)
# Note that volumes are assumed to follow the name: <node_name>_data, e.g. es01_data
es_data_volumes_exist() {
    local project="${1:-}"
    shift
    local es_nodes=("$@")

    for node in "${es_nodes[@]}"; do
        local volume_name="${node}_data"
        docker volume ls -q \
            --filter label=com.docker.compose.volume="$volume_name" \
            --filter label=com.docker.compose.project="$project" |
            grep -q ^ && return 0
    done
    return 1
}

# Checks if the specified command is a startup Compose command
# Those commands need an extra check for "multi" and "multi-bootstrap" modes
is_startup_command() {
    case "${1:-}" in
        up|start|restart|create|run) return 0 ;;
        *) return 1 ;;
    esac
}

COMPOSE_FILE_BASE="compose.yaml"
COMPOSE_FILE_MULTI_NODE="compose.multi-node.yaml"
COMPOSE_FILE_MULTI_NODE_BOOTSTRAP="compose.multi-node.bootstrap.yaml"

# Elasticsearch node names, as specified in the Compose files
ES_NODES=(es01 es02 es03)


[[ $# -eq 0 ]] && { usage >&2 ; exit 1; }

ARGS=("-f" "$COMPOSE_FILE_BASE")
case "${1:-}" in
    multi)
        ARGS+=("-f" "$COMPOSE_FILE_MULTI_NODE")
        shift
        if is_startup_command "${1:-}"; then
            compose_project="$(get_compose_project_name "${ARGS[@]}")"
            es_data_volumes_exist "$compose_project" "${ES_NODES[@]}" ||
                { echo "$0: no ES data volumes exist -- you probably want to use '$0 multi-bootstrap $@' instead" >&2; exit 1; }
        fi
        ;;
    multi-bootstrap)
        ARGS+=("-f" "$COMPOSE_FILE_MULTI_NODE" "-f" "$COMPOSE_FILE_MULTI_NODE_BOOTSTRAP")
        shift
        if is_startup_command "${1:-}"; then
            compose_project="$(get_compose_project_name "${ARGS[@]}")"
            es_data_volumes_exist "$compose_project" "${ES_NODES[@]}" &&
                { echo "$0: found existing ES data volume(s) -- you probably want to use '$0 multi $@' instead" >&2; exit 1; }
        fi
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
