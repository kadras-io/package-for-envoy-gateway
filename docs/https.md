# HTTPS

The external Gateway can terminate TLS, with certificates issued by a cert-manager `ClusterIssuer`. cert-manager must be installed in the cluster.

## Domain

When `domain` and `tls.issuer` are set, the package requests a wildcard certificate for `*.<domain>` and adds an HTTPS listener for it to the external Gateway. With an ACME issuer like Let's Encrypt, wildcard certificates require a DNS-01 challenge.

```yaml
gateways:
  external:
    domain: example.com
    tls:
      issuer: letsencrypt-prod-issuer
```

## Hostnames

Additional hostnames are served over HTTPS, each with its own listener and certificate. Wildcard hostnames are useful to serve the applications of a namespace, since a wildcard certificate only covers one level of subdomains. For example, Knative Services in the `team-a` namespace are served as `<name>.team-a.example.com`.

```yaml
gateways:
  external:
    domain: example.com
    tls:
      issuer: letsencrypt-prod-issuer
      hostnames:
        - "*.team-a.example.com"
        - www.example.org
```

A Gateway supports at most 64 listeners: one for HTTP, one for `domain`, and one for each hostname.

## HTTP to HTTPS redirect

When `tls.issuer` is set, the HTTP listener only redirects requests to HTTPS (`301`), and serves the ACME HTTP-01 challenges of cert-manager. Routes from other namespaces only attach to the HTTPS listeners. To serve HTTP too, disable the redirect.

```yaml
gateways:
  external:
    tls:
      http_redirect: false
```

## TLS version

The HTTPS listeners only accept TLS 1.3 connections, via a ClientTrafficPolicy targeting the external Gateway. To also accept TLS 1.2, for example for older clients:

```yaml
gateways:
  external:
    tls:
      min_version: "1.2"
```

For more information, check the Envoy Gateway documentation on [using cert-manager](https://gateway.envoyproxy.io/docs/tasks/security/tls-cert-manager/) and [HTTP redirects](https://gateway.envoyproxy.io/docs/tasks/traffic/http-redirect/), and [securing Gateways](https://gateway.envoyproxy.io/docs/tasks/security/secure-gateways/).
