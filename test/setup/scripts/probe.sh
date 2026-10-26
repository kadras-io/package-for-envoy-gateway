#!/usr/bin/env sh
# Sends a request to the given URL through the Envoy Service of a Gateway, from the `curl` Pod in the cluster,
# and checks the HTTP status code. Extra arguments are passed to curl.
#   test/setup/scripts/probe.sh <envoy service> <url> <expected status code> [curl args...]
set -eu
service=$1
url=$2
expected=$3
shift 3
host=$(echo "$url" | sed -E 's#^[a-z]+://([^/]+).*#\1#')
ip=$(kubectl get service "$service" -n envoy-gateway-system -o jsonpath='{.spec.clusterIP}')
code=$(kubectl exec -n tests curl -- curl -sk --max-time 5 -o /dev/null -w '%{http_code}' \
  --resolve "$host:80:$ip" --resolve "$host:443:$ip" "$@" "$url")
echo "$url: $code"
[ "$code" = "$expected" ]
