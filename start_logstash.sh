#!/bin/bash
# Creates a Logstash container.
# To test connectivity to Elasticsearch, you can run:
#  curl --cacert /usr/share/logstash/config/certs/ca.crt -u "elastic:${ELASTIC_PASSWORD}" -XGET https://es01:9200/

set -euo pipefail
IFS=$'\n\t'

[ -f .env ] && source .env || { echo "$0: cannot find .env file" >&2; exit 1; }

LOGSTASH_DIR="/usr/share/logstash"
LOGSTASH_PIPELINE_DIR="${LOGSTASH_DIR}/pipeline"
LOGSTASH_CONF_DIR="${LOGSTASH_DIR}/config"
LOGSTASH_CERT_DIR="${LOGSTASH_CONF_DIR}/certs"

CONTAINER_NAME="logstash01"
NETWORK="${COMPOSE_PROJECT_NAME}_internal"
CA_CERTS_VOLUME="${COMPOSE_PROJECT_NAME}_ca_certs"
LOGSTASH_DATA_VOLUME="${COMPOSE_PROJECT_NAME}_logstash01_data"

docker run --rm --name "${CONTAINER_NAME}" --network "${NETWORK}" \
    -v "${CA_CERTS_VOLUME}:${LOGSTASH_CERT_DIR}/ca" \
    -v "${LOGSTASH_DATA_VOLUME}:${LOGSTASH_DIR}/data" \
    -v "$(pwd)/logstash-ingest-data:${LOGSTASH_DIR}/ingest-data" \
    -v "$(pwd)/logstash-pipelines:${LOGSTASH_PIPELINE_DIR}" \
    -v "$(pwd)/logstash-pipelines.yml:${LOGSTASH_CONF_DIR}/pipelines.yml" \
    -e ELASTIC_HOSTS="https://es01:9200" \
    -e ELASTIC_USER="elastic" \
    -e ELASTIC_PASSWORD="${ELASTIC_PASSWORD}" \
    -e SSL_CERTIFICATEAUTHORITIES="${LOGSTASH_CERT_DIR}/ca/ca.crt" \
    --memory "${LS_MEM_LIMIT}" \
    docker.elastic.co/logstash/logstash:${STACK_VERSION}
