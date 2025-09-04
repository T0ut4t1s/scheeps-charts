# OAuth2 Proxy Helm Chart

A Helm chart for deploying OAuth2 Proxy with OIDC authentication and Keycloak integration.

## Description

This chart deploys OAuth2 Proxy as a reverse proxy and authentication service. It provides secure authentication using OpenID Connect (OIDC) with Keycloak integration, supporting role-based access control for downstream applications.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- A configured Keycloak realm with OIDC client
- External secrets containing client credentials

## Installation

```bash
helm repo add scheeps-charts https://your-repo-url
helm install my-oauth2-proxy scheeps-charts/oauth2-proxy
```

## Configuration

The following table lists the configurable parameters of the OAuth2 Proxy chart and their default values.

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | OAuth2 Proxy image repository | `quay.io/oauth2-proxy/oauth2-proxy` |
| `image.tag` | OAuth2 Proxy image tag | `v7.4.0` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `nameOverride` | Override the name of the chart | `""` |
| `fullnameOverride` | Override the full name of the release | `""` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `4180` |
| `service.targetPort` | Container target port | `4180` |
| `service.name` | Service port name | `http` |

### Resource Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU resource limits | `100m` |
| `resources.limits.memory` | Memory resource limits | `128Mi` |
| `resources.requests.cpu` | CPU resource requests | `50m` |
| `resources.requests.memory` | Memory resource requests | `64Mi` |

### OAuth2 Proxy Configuration

#### Provider Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `oauth2Proxy.provider` | OAuth2 provider type | `oidc` |
| `oauth2Proxy.oidcIssuerUrl` | OIDC issuer URL | `https://auth.scheeps.online/realms/scheeps` |
| `oauth2Proxy.clientId` | OIDC client ID | `vlan-manager` |

#### URL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `oauth2Proxy.redirectUrl` | OAuth2 redirect URL | `https://vlan.scheeps.online/oauth2/callback` |
| `oauth2Proxy.upstreams` | Upstream service URL | `http://vlan-manager-frontend.network-management.svc.cluster.local:80` |

#### Server Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `oauth2Proxy.httpAddress` | HTTP server bind address | `0.0.0.0:4180` |
| `oauth2Proxy.reverseProxy` | Enable reverse proxy mode | `true` |
| `oauth2Proxy.skipProviderButton` | Skip provider selection button | `true` |

#### Cookie Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `oauth2Proxy.cookieDomains` | Cookie domains | `vlan.scheeps.online` |
| `oauth2Proxy.cookieSecure` | Enable secure cookies | `true` |
| `oauth2Proxy.cookiePath` | Cookie path | `/` |
| `oauth2Proxy.cookieSamesite` | Cookie SameSite policy | `lax` |
| `oauth2Proxy.cookieRefresh` | Cookie refresh interval | `1m` |
| `oauth2Proxy.cookieExpire` | Cookie expiration time | `4h` |

#### Authentication Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `oauth2Proxy.emailDomains` | Allowed email domains | `*` |
| `oauth2Proxy.scope` | OAuth2 scope | `openid profile email roles` |
| `oauth2Proxy.oidcGroupsClaim` | OIDC groups claim name | `realm_access_roles` |
| `oauth2Proxy.allowedGroups` | Allowed user groups (comma-separated) | `vlan-manager-admin,vlan-manager-user` |
| `oauth2Proxy.whitelistDomains` | Whitelisted domains | `auth.scheeps.online` |

#### Header Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `oauth2Proxy.setAuthorizationHeader` | Set Authorization header | `true` |
| `oauth2Proxy.setXAuthRequest` | Set X-Auth-Request headers | `true` |
| `oauth2Proxy.passAuthorizationHeader` | Pass Authorization header upstream | `true` |

### Secret Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `secrets.name` | Name of the secret containing OAuth2 credentials | `vlan-keycloak-secret` |
| `secrets.clientSecretKey` | Key name for client secret in the secret | `client_secret` |
| `secrets.cookieSecretKey` | Key name for cookie secret in the secret | `cookie_secret` |

### Advanced Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable horizontal pod autoscaling | `false` |
| `nodeSelector` | Node selector for pod assignment | `{}` |
| `tolerations` | Tolerations for pod assignment | `[]` |
| `affinity` | Affinity rules for pod assignment | `{}` |
| `podAnnotations` | Annotations to add to pods | `{}` |
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | `{}` |

### Service Account Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create a service account | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name (generated if empty) | `""` |

## Required Secrets

This chart requires a Kubernetes secret containing OAuth2 credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: vlan-keycloak-secret
type: Opaque
data:
  client_secret: <base64-encoded-client-secret>
  cookie_secret: <base64-encoded-cookie-secret>
```

## Example Values

```yaml
replicaCount: 1

oauth2Proxy:
  oidcIssuerUrl: "https://your-keycloak.domain.com/realms/your-realm"
  clientId: "your-oauth2-client"
  redirectUrl: "https://your-app.domain.com/oauth2/callback"
  upstreams: "http://your-app-service:80"
  cookieDomains: "your-app.domain.com"
  allowedGroups: "your-admin-group,your-user-group"

secrets:
  name: "your-oauth2-secret"

resources:
  limits:
    memory: "256Mi"
    cpu: "200m"
```

## Keycloak Configuration

To use this chart with Keycloak, ensure your OIDC client is configured with:

1. **Client Type**: OpenID Connect
2. **Access Type**: Confidential
3. **Valid Redirect URIs**: `https://your-domain.com/oauth2/callback`
4. **Mappers**: Ensure `realm_access_roles` claim is included in tokens

## Integration with Rancher

This chart is designed to work seamlessly with Rancher:

- Namespace management is handled by Rancher during deployment
- All configuration is exposed through Helm values
- Compatible with Rancher's Helm chart repository system

## Troubleshooting

### Common Issues

1. **Authentication loops**: Check redirect URLs match between chart and Keycloak
2. **Group access denied**: Verify `allowedGroups` matches user's Keycloak roles
3. **Cookie issues**: Ensure `cookieDomains` matches your application domain

### Logs

View OAuth2 Proxy logs:
```bash
kubectl logs -l app.kubernetes.io/name=oauth2-proxy
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This chart is licensed under the Apache License 2.0.