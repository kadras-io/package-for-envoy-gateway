# Security

## Pod Security Standards

Envoy Gateway, the certgen Job, and the Envoy proxies comply with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), which is enforced on the package namespace, where the Envoy proxies run too.

## Image verification

The Envoy Gateway and Envoy images aren't signed upstream, so the package doesn't include Kyverno policies to verify them. The package itself is signed, see [verify-release.md](verify-release.md).

## Security policies

Envoy Gateway can enforce authentication, authorization, CORS, and rate limiting on the routes, via [SecurityPolicy](https://gateway.envoyproxy.io/docs/tasks/security/) and [BackendTrafficPolicy](https://gateway.envoyproxy.io/docs/tasks/traffic/) resources. Rate limiting with a global store requires enabling the rate limit service via `controller.config`.

## Access control

The Gateways, their EnvoyProxy resources, and the policies attached to them live in the package namespace, so only the administrators with access to it can change them. Following the Envoy Gateway [threat model](https://gateway.envoyproxy.io/docs/tasks/security/threat-model/), restrict who can:

* create Gateways and GatewayClasses, so that only the Gateways of the package expose traffic;
* create ReferenceGrants, which allow routes to reference Services and Secrets across namespaces;
* create EnvoyPatchPolicy resources, which can change any part of the Envoy configuration.

Application developers only need to create routes in their own namespaces, and attach them to the Gateways.
