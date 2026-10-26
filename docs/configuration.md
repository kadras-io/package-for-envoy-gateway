# Configuration

The package values cover the decisions most installations need to make: exposure, HTTPS, high availability, observability, and TLS. Everything else can still be customized in three ways.

## Envoy Gateway configuration

Envoy Gateway reads its [configuration](https://gateway.envoyproxy.io/docs/api/extension_types/#envoygateway) from the `envoy-gateway-config` ConfigMap. The package computes it from the values, then merges `controller.config` on top, so its keys take precedence.

```yaml
controller:
  config:
    extensionApis:
      enableBackend: true
```

## EnvoyProxy configuration

The Envoy proxies of each Gateway are configured via an [EnvoyProxy](https://gateway.envoyproxy.io/docs/api/extension_types/#envoyproxy) resource. The package computes it from the values, then merges `envoy.config` on top, for every Gateway.

```yaml
envoy:
  config:
    provider:
      kubernetes:
        envoyDeployment:
          pod:
            nodeSelector:
              node-role.kubernetes.io/ingress: ""
```

## ytt overlays

Any Kubernetes resource of the package can be customized with a [ytt overlay](https://carvel.dev/ytt/docs/latest/ytt-overlays/), stored in a Secret and referenced from the PackageInstall via the `ext.packaging.carvel.dev/ytt-paths-from-secret-name.0` annotation.

```shell
kubectl create secret generic envoy-gateway-overlays -n kadras-system --from-file=overlays.yml
kubectl annotate packageinstall envoy-gateway -n kadras-system \
  ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=envoy-gateway-overlays
```

For example, to set the resources of Envoy Gateway:

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "envoy-gateway"}})
---
spec:
  template:
    spec:
      containers:
        #@overlay/match by="name"
        - name: envoy-gateway
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
```
