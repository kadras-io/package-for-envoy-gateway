load("@ytt:regexp", "regexp")

# Validation helpers used by the values schema, and by the overlays to interpret the values they validate.
# They must not depend on data values, since they run while the schema is evaluated.

_dns_label = "[a-z0-9]([-a-z0-9]*[a-z0-9])?"

def is_dns_label(value):
  return len(value) <= 63 and regexp.match("^" + _dns_label + "$", value)
end

def is_dns_name(value):
  return regexp.match("^" + _dns_label + "(\\." + _dns_label + ")*$", value)
end

# A hostname for a Gateway listener: a DNS name, optionally prefixed with a `*.` wildcard label.
def is_listener_hostname(value):
  return is_dns_name(value[2:] if value.startswith("*.") else value)
end

# A name derived from a hostname, valid for listeners and Secrets: `*.team-a.example.com` becomes `wildcard-team-a-example-com`.
def hostname_slug(hostname):
  return hostname.replace("*.", "wildcard-").replace(".", "-")
end

def is_hours(value):
  return regexp.match("^[1-9][0-9]*h$", value)
end

def hours(value):
  return int(value[:-1])
end

def is_duration(value):
  return regexp.match("^([0-9]+(ms|s|m|h))+$", value)
end

# An OTLP/gRPC endpoint served by an in-cluster Service, with an optional `http://` scheme.
# Examples: `otel-collector.observability:4317`, `http://otel-collector.observability.svc.cluster.local:4317`.
def is_in_cluster_otlp_endpoint(value):
  return regexp.match("^(http://)?" + _dns_label + "\\." + _dns_label + "(\\.svc(\\.cluster\\.local)?)?:[0-9]{1,5}$", value)
end
