# Observability

## Logs

The log level applies to Envoy Gateway and to the Envoy proxies. The Envoy proxies also write access logs to the standard output.

```yaml
observability:
  logging:
    level: debug
```

## Metrics

By default, Envoy Gateway and the Envoy proxies expose their metrics on port 19001 in the Prometheus format, and their Pods are annotated for scraping. Alternatively, they push them via OTLP/gRPC to an in-cluster OpenTelemetry collector.

```yaml
observability:
  metrics:
    exporter: otlp
    endpoint: http://otel-collector.observability.svc:4317
```

## Traces

The Envoy proxies can export the traces of the requests they handle via OTLP/gRPC.

```yaml
observability:
  tracing:
    enabled: true
    endpoint: http://otel-collector.observability.svc:4317
    sampling_rate: 0.1
```

For more information, check the Envoy Gateway documentation on [observability](https://gateway.envoyproxy.io/docs/tasks/observability/gateway-observability/).
