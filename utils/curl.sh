#!/bin/bash
# A shell wrapper around curl to predefine common arguments and save some typing.
# Example usage (replace '{index}' with the index name):
#  ./curl.sh -XGET 'https://localhost:9200/{index}/_search?pretty' -d '{"query": {"match": {"field": "value"}}}'
#  ./curl.sh -XPOST 'https://localhost:9200/_bulk?pretty' --data-binary @documents.ndjson

set -euo pipefail
IFS=$'\n\t'


ELASTIC_USER="elastic"
ELASTIC_PASSWORD="elastic"

# NOTE: Update the path to the cert file if needed
CA_CERT_FILE="ca.crt"
# For normal requests, such as queries
CONTENT_TYPE="application/json"
# For bulk requests, e.g. /_bulk or /{index}/_bulk (POST or PUT)
# CONTENT_TYPE="application/x-ndjson"

curl --cacert "$CA_CERT_FILE" -u "$ELASTIC_USER:$ELASTIC_PASSWORD" -H "Content-Type: $CONTENT_TYPE" "$@"
