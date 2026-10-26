#!/usr/bin/env bash
#
# Checks that the Envoy image pinned in the package (`envoy_image` in package/config/lib/envoy_gateway.star)
# is the default one of the vendored Envoy Gateway release (`DefaultEnvoyProxyImage`), since the upstream
# manifests don't reference it and it must be updated by hand at every upgrade.
#
#   hack/check-envoy-image.sh

set -euo pipefail

version=$(sed -n 's/^ *tag: //p' package/vendir.yml)
source_url="https://raw.githubusercontent.com/envoyproxy/gateway/$version/api/v1alpha1/shared_types.go"

expected=$(curl -fsSL "$source_url" | sed -n 's/^\s*DefaultEnvoyProxyImage = "\(.*\)"/\1/p')
actual=$(sed -n 's/^envoy_image = "\(.*\)"/\1/p' package/config/lib/envoy_gateway.star)

if [[ -z $expected ]]; then
  echo "❌ Couldn't find DefaultEnvoyProxyImage in $source_url"
  exit 1
fi

if [[ $expected != "$actual" ]]; then
  echo "❌ The pinned Envoy image doesn't match the default of Envoy Gateway $version."
  echo "   Set envoy_image in package/config/lib/envoy_gateway.star to:"
  echo "   $expected"
  exit 1
fi

echo "✅ Envoy image matches the default of Envoy Gateway $version"
