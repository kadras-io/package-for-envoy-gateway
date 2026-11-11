# Access to the Resources

The package extends the Kubernetes [default roles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) with the Envoy Gateway resources, via [aggregation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles). The users bound to `admin`, `edit`, or `view` in a namespace get the following permissions on the resources in that namespace.

| Resources | `admin`, `edit` | `view` |
|-----------|-----------------|--------|
| BackendTrafficPolicy, SecurityPolicy, HTTPRouteFilter | Read and write | Read |
| Backend, EnvoyExtensionPolicy, EnvoyPatchPolicy, ClientTrafficPolicy, EnvoyProxy | Read | Read |

The policies and filters attached to the routes of a namespace, like rate limiting, retries, and authentication, can be managed by the users of the namespace. The other resources affect the Gateways and the Envoy proxies shared by all the namespaces, so they're read-only:

* Backends can route traffic to any address, including the ones of other namespaces and of the cluster nodes;
* EnvoyExtensionPolicies run code in the shared proxies, via Wasm or external processing;
* EnvoyPatchPolicies patch the configuration of the shared proxies;
* ClientTrafficPolicies and EnvoyProxies configure the Gateways, managed by the platform.

The permissions are granted by the `envoy-gateway-edit` and `envoy-gateway-view` ClusterRoles. To grant more to a trusted team, bind an additional role in its namespace.

The permissions on the Gateway API resources, like HTTPRoutes, are granted by the [Gateway API](https://github.com/kadras-io/package-for-gateway-api) package.
