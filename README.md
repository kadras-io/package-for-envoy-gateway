# Envoy Gateway

![Test Workflow](https://github.com/kadras-io/package-for-envoy-gateway/actions/workflows/test.yml/badge.svg)
![Release Workflow](https://github.com/kadras-io/package-for-envoy-gateway/actions/workflows/release.yml/badge.svg)
[![The SLSA Level 3 badge](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev/spec/v1.0/levels)
[![The Apache 2.0 license badge](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Follow us on Bluesky](https://img.shields.io/static/v1?label=Bluesky&message=Follow&color=1DA1F2)](https://bsky.app/profile/kadras.bsky.social)

A Carvel package for [Envoy Gateway](https://gateway.envoyproxy.io), which manages Envoy proxies as application gateways, configured via the Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io).

## ✨&nbsp; What's Included

* **Gateway API**. An `external` Gateway exposing applications outside the cluster, and an `internal` Gateway for traffic within the cluster, each with its own Envoy proxies.
* **HTTPS**. TLS terminated on the external Gateway, with wildcard certificates from cert-manager for your domain and for additional hostnames, like one per namespace. HTTP requests are redirected to HTTPS.
* **High availability**. Configurable replicas for Envoy Gateway and the Envoy proxies of each Gateway, protected by PodDisruptionBudgets. The Envoy proxies drain their connections before terminating.
* **Observability**. Prometheus metrics, or metrics and traces exported via OpenTelemetry.
* **TLS**. Mutual TLS between Envoy Gateway and the Envoy proxies, with certificates generated at installation or issued by cert-manager.
* **Security**. The workloads comply with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), enforced on the package namespace.

## 🚀&nbsp; Getting Started

### Prerequisites

* Kubernetes 1.35+
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

```shell
kapp deploy -a kapp-controller -y \
  -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
```

### Dependencies

Envoy Gateway has no required dependencies. [cert-manager](https://github.com/kadras-io/package-for-cert-manager) is needed to serve HTTPS on the external Gateway (`gateways.external.tls.issuer`) and to issue the certificates between Envoy Gateway and the Envoy proxies (`tls.internal.provider: cert-manager`). You can install it from the [Kadras package repository](https://github.com/kadras-io/kadras-packages).

The package installs the Gateway API CRDs from the experimental channel, in the version required by Envoy Gateway. Don't install it alongside the Kadras Contour package, which installs an older version of them.

### Installation

Add the Kadras [package repository](https://github.com/kadras-io/kadras-packages) to your Kubernetes cluster:

```shell
kctrl package repository add -r kadras-packages \
  --url ghcr.io/kadras-io/kadras-packages \
  -n kadras-system --create-namespace
```

<details><summary>Installation without package repository</summary>
The recommended way of installing the Envoy Gateway package is via the Kadras <a href="https://github.com/kadras-io/kadras-packages">package repository</a>. If you prefer not using the repository, you can add the package definition directly using <a href="https://carvel.dev/kapp/docs/latest/install"><code>kapp</code></a> or <code>kubectl</code>.

```shell
kubectl create namespace kadras-system
kapp deploy -a envoy-gateway-package -n kadras-system -y \
  -f https://github.com/kadras-io/package-for-envoy-gateway/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/package-for-envoy-gateway/releases/latest/download/package.yml
```
</details>

Install the Envoy Gateway package:

```shell
kctrl package install -i envoy-gateway \
  -p envoy-gateway.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system
```

> **Note**
> You can find the `${VERSION}` value by retrieving the list of package versions available in the Kadras package repository installed on your cluster.
>
> ```shell
> kctrl package available list -p envoy-gateway.packages.kadras.io -n kadras-system
> ```

Verify the installed packages and their status:

```shell
kctrl package installed list -n kadras-system
```

### Try It Out

Deploy an application and route traffic to it through the external Gateway:

```shell
kubectl create deployment hello --image=ghcr.io/knative/helloworld-go:latest --port=8080
kubectl expose deployment hello --port=80 --target-port=8080

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: hello
spec:
  parentRefs:
    - name: external
      namespace: envoy-gateway-system
  hostnames:
    - hello.example.com
  rules:
    - backendRefs:
        - name: hello
          port: 80
EOF
```

Send a request to the Envoy Service of the external Gateway.

```shell
ADDRESS=$(kubectl get service envoy-external -n envoy-gateway-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -H "Host: hello.example.com" http://$ADDRESS
```

## 📙&nbsp; Documentation

Documentation, tutorials and examples for this package are available in the [docs](docs) folder.
For documentation specific to Envoy Gateway, check out [gateway.envoyproxy.io](https://gateway.envoyproxy.io).

Features:

* [Gateways](docs/gateways.md)
* [HTTPS](docs/https.md)
* [High availability](docs/high-availability.md)
* [Observability](docs/observability.md)
* [TLS between the components](docs/tls.md)
* [Security](docs/security.md)

Operations:

* [Configuration and ytt overlays](docs/configuration.md)
* [Verifying the release](docs/verify-release.md)

## 🎯&nbsp; Configuration

The Envoy Gateway package can be customized via a `values.yml` file.

```yaml
gateways:
  external:
    domain: example.com
    tls:
      issuer: letsencrypt-prod-issuer
      hostnames:
        - "*.team-a.example.com"
tls:
  internal:
    provider: cert-manager
```

Reference the `values.yml` file from the `kctrl` command when installing or upgrading the package.

```shell
kctrl package install -i envoy-gateway \
  -p envoy-gateway.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system \
  --values-file values.yml
```

Anything not covered by the values can be customized via the Envoy Gateway and EnvoyProxy configuration, or ytt overlays, as described in [docs/configuration.md](docs/configuration.md).

### Values

The Envoy Gateway package has the following configurable properties.

<details><summary>Configurable properties</summary>

<!-- values-table:start -->

| Config | Default | Description |
|--------|---------|-------------|
| `namespace` | `"envoy-gateway-system"` | The namespace in which to deploy Envoy Gateway. The Envoy proxies of the Gateways run in the same namespace. |
| `gateways.external.enabled` | `true` | Whether to create the external Gateway. |
| `gateways.external.name` | `"external"` | The name of the Gateway, created in the package namespace. Its Envoy Service is named `envoy-<name>`. |
| `gateways.external.allowed_routes` | `"All"` | The namespaces from which routes can attach to the Gateway. `All` allows any namespace, `Same` only the package namespace. |
| `gateways.external.domain` | `""` | The domain served over HTTPS by the Gateway via a wildcard certificate (`*.<domain>`). It requires `tls.issuer`. |
| `gateways.external.tls.issuer` | `""` | The name of the cert-manager ClusterIssuer that issues the certificates for `domain` and `hostnames`. For ACME issuers, wildcard certificates require a DNS-01 challenge. |
| `gateways.external.tls.min_version` | `"1.3"` | The minimum TLS version accepted by the HTTPS listeners. |
| `gateways.external.tls.http_redirect` | `true` | Whether to redirect all HTTP requests to HTTPS. Only applied when `issuer` is set: the HTTP listener then only serves the redirect, and the ACME HTTP-01 challenges of cert-manager. |
| `gateways.external.tls.hostnames` | `[]` | Additional hostnames served over HTTPS, each with its own listener and certificate. Use a wildcard like `*.team-a.example.com` to serve the applications of a namespace with Knative Serving. |
| `gateways.internal.enabled` | `true` | Whether to create the internal Gateway. |
| `gateways.internal.name` | `"internal"` | The name of the Gateway, created in the package namespace. Its Envoy Service is named `envoy-<name>`. Routes can attach to it from any namespace. |
| `controller.replicas` | `1` | The number of replicas. Additional replicas are standby via leader election. With more than 1 replica, a PodDisruptionBudget is created. |
| `controller.config` | `{}` | Envoy Gateway configuration, merged on top of the one computed by the package. See https://gateway.envoyproxy.io/docs/api/extension_types/#envoygateway. |
| `envoy.replicas` | `1` | The number of Envoy replicas for each Gateway. With more than 1 replica, a PodDisruptionBudget is created. |
| `envoy.drain_timeout` | `"60s"` | How long Envoy drains the open connections before terminating, as a duration. |
| `envoy.service.type` | `"LoadBalancer"` | The type of the Service. |
| `envoy.service.external_traffic_policy` | `"Local"` | The external traffic policy of the Service, when `type` is `LoadBalancer` or `NodePort`. `Local` preserves the client source IP. |
| `envoy.service.annotations` | `{}` | Annotations for the Service, for example to configure the load balancer implementation. |
| `envoy.service.proxy_protocol` | `false` | Whether the load balancer in front of the Service sends the PROXY protocol, to preserve the client source IP. Envoy then rejects the connections without it. Enable it together with the load balancer setting, like the `load-balancer.hetzner.cloud/uses-proxyprotocol` annotation on Hetzner. |
| `envoy.config` | `{}` | EnvoyProxy configuration, merged on top of the one computed by the package for every Gateway. See https://gateway.envoyproxy.io/docs/api/extension_types/#envoyproxyspec. |
| `tls.internal.provider` | `"certgen"` | How the certificates are provisioned. `certgen` generates them with a Job at installation, and doesn't renew them. `cert-manager` issues and renews them via cert-manager, which must be installed in the cluster. |
| `tls.internal.duration` | `"8760h"` | How long the certificates are valid, in hours. Only for the `cert-manager` provider. |
| `tls.internal.renew_before` | `"360h"` | How long before expiry the certificates are renewed, in hours. Only for the `cert-manager` provider. |
| `observability.logging.level` | `"info"` | The log level for Envoy Gateway and the Envoy proxies. |
| `observability.metrics.enabled` | `true` | Whether to produce metrics. |
| `observability.metrics.exporter` | `"prometheus"` | How the metrics are exported. With `prometheus`, Envoy Gateway and the Envoy proxies expose them on port 19001, and their Pods are annotated for scraping. With `otlp`, they push them via OTLP/gRPC to `endpoint`. |
| `observability.metrics.endpoint` | `""` | The OTLP/gRPC endpoint of an in-cluster OpenTelemetry collector, in the form `[http://]<service>.<namespace>[.svc[.cluster.local]]:<port>`. Required with the `otlp` exporter. |
| `observability.tracing.enabled` | `false` | Whether to export the traces of the requests handled by the Envoy proxies via OTLP/gRPC. |
| `observability.tracing.endpoint` | `""` | The OTLP/gRPC endpoint of an in-cluster OpenTelemetry collector, in the form `[http://]<service>.<namespace>[.svc[.cluster.local]]:<port>`. |
| `observability.tracing.sampling_rate` | `1` | The fraction of requests to trace, from 0 (never) to 1 (always). |

<!-- values-table:end -->

</details>

## 🛠️&nbsp; Development

The development environment is defined with [devenv](https://devenv.sh). Enter it with `devenv shell`, or automatically with [direnv](https://direnv.net) after running `direnv allow`. Run `task --list` to see all the available tasks.

```shell
# Run the unit tests, which render the package and check the result without a cluster.
task test:config

# Create a local kind cluster and run the integration tests on it.
task cluster:setup
task test:integration

# Deploy the package from the local sources to the current cluster.
task dev

# Update the table of configurable values in this README after changing the values schema.
task docs:values
```

The unit tests are described in [test/unit/README.md](test/unit/README.md).

## 🛡️&nbsp; Security

The security process for reporting vulnerabilities is described in [SECURITY.md](SECURITY.md).

## 🖊️&nbsp; License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for more information.
