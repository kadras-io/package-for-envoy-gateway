# High Availability

## Envoy Gateway

Envoy Gateway runs with leader election: additional replicas are standby for status updates, and all of them serve the configuration to the Envoy proxies. With more than one replica, a PodDisruptionBudget keeps at least one available.

```yaml
controller:
  replicas: 2
```

## Envoy

By default, the Envoy proxies of each Gateway run a single replica. Upgrades and configuration changes start the new replica before stopping the old one, so they don't interrupt the traffic. Node drains and failures do, until the replica is rescheduled. For production, run at least 2 replicas: a PodDisruptionBudget then keeps at least one available during node drains. Spread them across nodes or zones via `topologySpreadConstraints` in the EnvoyProxy configuration (see below).

```yaml
envoy:
  replicas: 2
```

When an Envoy proxy terminates, it stops accepting new connections and drains the open ones for up to `drain_timeout`. See [graceful shutdown](https://gateway.envoyproxy.io/docs/tasks/operations/graceful-shutdown/).

```yaml
envoy:
  drain_timeout: 90s
```

## Autoscaling and resources

The Envoy proxies can be scaled by a HorizontalPodAutoscaler, and their resources configured, via the EnvoyProxy configuration. See [customize EnvoyProxy](https://gateway.envoyproxy.io/docs/tasks/operations/customize-envoyproxy/).

```yaml
envoy:
  config:
    provider:
      kubernetes:
        envoyHpa:
          minReplicas: 2
          maxReplicas: 10
        envoyDeployment:
          container:
            resources:
              requests:
                cpu: 500m
                memory: 512Mi
```
