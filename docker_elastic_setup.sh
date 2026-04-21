#!/bin/bash
# Setup script for the setup container in docker-compose.yml.
# Based on https://github.com/elastic/elasticsearch/blob/main/docs/reference/setup/install/docker/docker-compose.yml

set -euo pipefail
IFS=$'\n\t'

ES_HOME_DIR="/usr/share/elasticsearch"

if ! [ "$PWD" = "$ES_HOME_DIR" ]; then
  echo "Incorrect PWD: expected: $ES_HOME_DIR, actual: $PWD"
  exit 1;
fi

if [ -z "${ELASTIC_PASSWORD:-}" ]; then
  echo "Set the ELASTIC_PASSWORD environment variable in the .env file"
  exit 1
elif [ -z "${KIBANA_PASSWORD:-}" ]; then
  echo "Set the KIBANA_PASSWORD environment variable in the .env file"
  exit 1
fi

if [ ! -f config/certs/ca.zip ]; then
  echo "Creating CA"
  bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip
  unzip config/certs/ca.zip -d config/certs
fi;

if [ ! -f config/certs/certs.zip ]; then
  echo "Creating certs"
  bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key
  unzip config/certs/certs.zip -d config/certs
fi

echo "Setting file permissions"
chown -R root:root config/certs
find config/certs -type d -exec chmod 750 \{\} \;
find config/certs -type f -exec chmod 640 \{\} \;

echo "Copying CA cert file"
cp config/certs/ca/ca.crt config/ca_certs/ca.crt
chmod 644 config/ca_certs/ca.crt
chmod 755 config/ca_certs

echo "Setting snapshot volume permissions"
chown 1000:0 /usr/share/elasticsearch/snapshots
chmod 775 /usr/share/elasticsearch/snapshots

echo "Waiting for Elasticsearch availability"
until curl -s --cacert config/certs/ca/ca.crt https://es01:9200 | grep -q "missing authentication credentials"; do sleep 10; done

echo "Setting kibana_system password";
until curl -s -X POST --cacert config/certs/ca/ca.crt -u "elastic:${ELASTIC_PASSWORD}" -H "Content-Type: application/json" https://es01:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;

echo "All done!"
