#!/usr/bin/env python3
# A Python wrapper around curl (requests) to predefine common arguments and save some typing.
# Example usage (replace '{index}' with the index name):
#  ./curl.py GET 'https://localhost:9200/{index}/_search?pretty' '{"query": {"match": {"field": "value"}}}'
#  ./curl.py GET '/{index}/_search?pretty' | jq '.hits.hits.[]._source.field'

import requests
import sys


ELASTIC_USER = "elastic"
ELASTIC_PASSWORD = "elastic"

# NOTE: Update the path to the cert file if needed
CA_CERT_FILE = "ca.crt"

HEADERS = {"Content-Type": "application/json"}

if len(sys.argv) < 3:
    print(f"usage: {sys.argv[0]} <method> <url> [body]")
    exit(1)

# HTTP method (e.g. GET, PUT, POST, DELETE)
method = sys.argv[1].upper()
# Example URL: https://localhost:9200/{index}/_search?pretty
url = sys.argv[2]
# Also allow commands like `python curl.py GET /{index}/_search?pretty`
if not url.startswith("https://"):
    url = "https://localhost:9200" + url

if len(sys.argv) == 4:
    payload = sys.argv[3]
else:
    payload = ""

# Specify the arguments to pass to the requests module, e.g.:
# res = requests.get(url, verify=CA_CERT_FILE, auth=(ELASTIC_USER, ELASTIC_PASSWORD), headers=HEADERS, data=payload)
args = {"url": url, "verify": CA_CERT_FILE, "auth": (ELASTIC_USER, ELASTIC_PASSWORD), "headers": HEADERS, "data": payload}

match method:
    case "GET":
        res = requests.get(**args)
    case "PUT":
        res = requests.put(**args)
    case "POST":
        res = requests.post(**args)
    case "DELETE":
        res = requests.delete(**args)
    case "HEAD":
        res = requests.head(**args)
    case _:
        print(f"Unknown HTTP method: {method}")
        exit(1)

print(res.text)
