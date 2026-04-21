#!/bin/bash
# A small script that simulates the search-as-you-type functionality.
# Based on http://media.sundog-soft.com/es/sayt.txt
# NOTE: The field must be mapped as 'search_as_you_type'

set -euo pipefail
IFS=$'\n\t'


RED="\e[1;91m"
BLUE="\e[1;94m"
GREEN="\e[1;92m"
YELLOW="\e[1;93m"
RESET="\e[0m"

INDEX="autocomplete"
QUERY='{
  "size": 5,
  "query": {
    "multi_match": {
      "query": $input,
      "type": "bool_prefix",
      "fields": ["title", "title._2gram", "title._3gram"]
    }
  }
}'
# NOTE: Update the path to the cert file if needed
CA_CERT_FILE="ca.crt"
ELASTIC_USER="elastic"
ELASTIC_PASSWORD="elastic"
HEADER="Content-Type: application/json"
URL="https://localhost:9200/${INDEX}/_search"

[ -f "$CA_CERT_FILE" ] || { echo "$0: cannot find certificate file $CA_CERT_FILE" >&2; exit 1; }

INPUT=
while : ; do
    echo -n ">$INPUT"
    IFS= read -rsn1 char
    # Exit if Enter is pressed
    if [[ "$char" = "" ]]; then
        echo -e "\n${GREEN}${INPUT}${RESET}"
        exit
    fi
    echo "$char"
    INPUT="${INPUT}${char}"
    PAYLOAD=$(jq -n --arg input "$INPUT" "$QUERY")
    curl -s --cacert "$CA_CERT_FILE" -u "$ELASTIC_USER:$ELASTIC_PASSWORD" -XGET -H "$HEADER" "$URL" -d "$PAYLOAD" |
        jq -r '.hits.hits[]._source.title' |
        grep -i --color=auto "$INPUT"
done
