# Gateways

The package creates the `envoy` GatewayClass and two Gateways in the package namespace. Envoy Gateway deploys dedicated Envoy proxies for each of them, configured via an EnvoyProxy resource with the same name as the Gateway. See the Envoy Gateway [concepts](https://gateway.envoyproxy.io/docs/concepts/).

| Gateway | Envoy Service | Listeners | Purpose |
|---------|---------------|-----------|---------|
| `external` | `envoy-external` (`LoadBalancer` by default) | HTTP on port 80, and HTTPS on port 443 when TLS is configured | Exposes applications outside the cluster. |
| `internal` | `envoy-internal` (always `ClusterIP`) | HTTP on port 80 | Serves traffic within the cluster, without exposing it outside. |

Attach a route to a Gateway by referencing it:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app
spec:
  parentRefs:
    - name: external
      namespace: envoy-gateway-system
  hostnames:
    - my-app.example.com
  rules:
    - backendRefs:
        - name: my-app
          port: 80
```

By default, routes from any namespace can attach to the external Gateway. Use `allowed_routes: Same` to only allow routes in the package namespace. Routes from any namespace can always attach to the internal Gateway.

```yaml
gateways:
  external:
    allowed_routes: Same
```

The Gateway names can be changed, and each Gateway can be disabled. The Envoy Service of a Gateway is always named `envoy-<gateway name>`.

```yaml
gateways:
  internal:
    enabled: false
```

## Exposure

The Envoy Service of the external Gateway is a `LoadBalancer` by default, with `externalTrafficPolicy: Local` to preserve the client source IP when the load balancer forwards it (otherwise, see the [PROXY protocol](#proxy-protocol)). It can be changed, and annotated to configure the load balancer implementation, like on Hetzner Cloud:

```yaml
envoy:
  service:
    annotations:
      load-balancer.hetzner.cloud/location: nbg1
      load-balancer.hetzner.cloud/name: kadras-lb
      load-balancer.hetzner.cloud/use-private-ip: "true"
```

With a `LoadBalancer` Service, the Gateway is `Programmed` once the Service has an address. Without a load balancer implementation, like on local clusters, expose the Service via node ports or only within the cluster, or install one like [cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind).

```yaml
envoy:
  service:
    type: NodePort
    external_traffic_policy: Cluster
```

### PROXY protocol

When the load balancer proxies the connections, Envoy sees the address of the load balancer instead of the one of the client, unless the load balancer sends it via the [PROXY protocol](https://www.haproxy.org/download/2.1/doc/proxy-protocol.txt). The client address is needed, for example, to restrict access by IP. Enable the PROXY protocol on both the load balancer and Envoy, which then rejects the connections without it. For example, on Hetzner:

```yaml
envoy:
  service:
    annotations:
      load-balancer.hetzner.cloud/location: nbg1
      load-balancer.hetzner.cloud/name: kadras-lb
      load-balancer.hetzner.cloud/use-private-ip: "true"
      load-balancer.hetzner.cloud/uses-proxyprotocol: "true"
    proxy_protocol: true
```

## Knative Serving

The [Knative Serving](https://github.com/kadras-io/package-for-knative-serving) package uses the external Gateway for the traffic from outside the cluster, and the internal Gateway for the cluster-local traffic. Serve the applications of each namespace with Knative Services over HTTPS with a wildcard hostname, as described in [https.md](https.md#hostnames).

## Uninstalling

When the package is deleted, Envoy Gateway removes the Envoy proxies of the Gateways. They drain their connections before terminating, and their termination grace period is 5 minutes longer than `envoy.drain_timeout`. The package namespace is deleted once they're gone, so uninstalling the package can take a few minutes.
