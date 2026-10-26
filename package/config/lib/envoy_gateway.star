load("@ytt:data", "data")
load("@ytt:struct", "struct")
load("/lib/validation.star", "hostname_slug")

# The Envoy proxy image used by Envoy Gateway by default (`DefaultEnvoyProxyImage` in the Envoy Gateway release).
# It's set explicitly on the EnvoyProxy resources, so that kbld can relocate it with the package.
# Update it together with the upstream version in `vendir.yml`: `task check:envoy-image` verifies they match.
envoy_image = "docker.io/envoyproxy/envoy:distroless-v1.39.5@sha256:9d84a586119a27b50437dbb01eccd4722832741539b1ed53c8e9d6da6067a6e0"

image_pull_secret_name = "canonical-registry-credentials"

# ########
# GATEWAYS
# ########

# Whether the HTTP listener of the external Gateway only redirects to HTTPS, which requires TLS.
def external_http_redirect():
  tls = data.values.gateways.external.tls
  return tls.issuer != "" and tls.http_redirect
end

# The HTTPS listeners of the external Gateway, as (listener name, hostname, certificate name) tuples.
def external_https_listeners():
  external = data.values.gateways.external
  listeners = []
  if external.domain:
    listeners.append(("https", "*." + external.domain, external.name + "-tls"))
  end
  for hostname in external.tls.hostnames:
    slug = hostname_slug(hostname)
    listeners.append(("https-" + slug, hostname, external.name + "-" + slug + "-tls"))
  end
  return listeners
end

# ########
# OBSERVABILITY
# ########

# Splits an endpoint like `http://otel-collector.observability.svc:4317` into its host and port.
def _otlp_host_port(endpoint):
  host, port = endpoint.split("://")[-1].rsplit(":", 1)
  return host, int(port)
end

# The metrics telemetry shared by Envoy Gateway and the Envoy proxies.
# The OTLP sink of Envoy Gateway also takes the protocol, passed via `sink_options`.
def _metrics_telemetry(sink_options={}):
  metrics = data.values.observability.metrics
  telemetry = {"prometheus": {"disable": not (metrics.enabled and metrics.exporter == "prometheus")}}
  if metrics.enabled and metrics.exporter == "otlp":
    host, port = _otlp_host_port(metrics.endpoint)
    telemetry["sinks"] = [{"type": "OpenTelemetry", "openTelemetry": dict({"host": host, "port": port}, **sink_options)}]
  end
  return telemetry
end

def _logging():
  return {"level": {"default": data.values.observability.logging.level}}
end

# ########
# ENVOY PROXY
# ########

# The EnvoyProxy configuration computed from the package values for a Gateway. `envoy.config` is merged on top of it.
# The Envoy Service is named `envoy-<gateway>`, so that other packages can reference it.
def envoy_proxy_spec(gateway_name, external):
  envoy = data.values.envoy
  service = {"name": "envoy-" + gateway_name, "type": "ClusterIP"}
  if external:
    service["type"] = envoy.service.type
    service["annotations"] = struct.decode(envoy.service.annotations)
    if envoy.service.type != "ClusterIP":
      service["externalTrafficPolicy"] = envoy.service.external_traffic_policy
    end
  end

  kubernetes = {
    "envoyDeployment": {
      "replicas": envoy.replicas,
      "container": {"image": envoy_image},
      "pod": {"imagePullSecrets": [{"name": image_pull_secret_name}]},
    },
    "envoyService": service,
  }
  if envoy.replicas > 1:
    kubernetes["envoyPDB"] = {"minAvailable": 1}
  end

  telemetry = {"metrics": _metrics_telemetry()}
  tracing = data.values.observability.tracing
  if tracing.enabled:
    host, port = _otlp_host_port(tracing.endpoint)
    telemetry["tracing"] = {
      # A fraction with 4 decimals.
      "samplingFraction": {"numerator": int(tracing.sampling_rate * 10000 + 0.5), "denominator": 10000},
      "provider": {"type": "OpenTelemetry", "host": host, "port": port},
    }
  end

  return {
    "provider": {"type": "Kubernetes", "kubernetes": kubernetes},
    "shutdown": {"drainTimeout": envoy.drain_timeout},
    "logging": _logging(),
    "telemetry": telemetry,
  }
end

# ########
# ENVOY GATEWAY
# ########

# The Envoy Gateway configuration computed from the package values. `controller.config` is merged on top of it.
def envoy_gateway_config():
  return {
    "logging": _logging(),
    "telemetry": {"metrics": _metrics_telemetry({"protocol": "grpc"})},
    # The rate limit service is deployed when global rate limiting is enabled via `controller.config`.
    "provider": {"kubernetes": {"rateLimitDeployment": {"pod": {"imagePullSecrets": [{"name": image_pull_secret_name}]}}}},
  }
end
