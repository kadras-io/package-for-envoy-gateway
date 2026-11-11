# TLS between the components

Envoy Gateway configures the Envoy proxies via xDS, over mutual TLS. The certificates are stored in the `envoy-gateway`, `envoy`, and `envoy-rate-limit` Secrets, and the `envoy-gateway` one also secures the Envoy Gateway webhook.

## certgen

By default, a Job generates the certificates at installation, if they don't exist yet, and doesn't renew them. The same Job also generates the `envoy-oidc-hmac` Secret, which Envoy Gateway uses to sign the OIDC cookies of SecurityPolicies.

## cert-manager

Alternatively, cert-manager can issue and renew the certificates, from a CA dedicated to the package. cert-manager must be installed in the cluster.

```yaml
tls:
  internal:
    provider: cert-manager
    duration: 8760h
    renew_before: 360h
```

The certgen Job still runs, once cert-manager has issued the certificates: it never replaces existing Secrets, so it only generates the `envoy-oidc-hmac` Secret. This is the same approach as the upstream Helm chart, which doesn't allow disabling the Job since OIDC depends on it.

For more information, check the Envoy Gateway documentation on [custom certificates](https://gateway.envoyproxy.io/docs/install/custom-cert/).
