# OAuth2-Proxy Helm Chart

This Helm chart deploys oauth2-proxy for OIDC authentication with Keycloak integration.

## Configuration

The chart is configured to use client-specific roles instead of realm roles to reduce cookie size and improve security isolation.

### Key Configuration Options

- **Provider**: OIDC with Keycloak
- **Client Roles**: Uses nested `resource_access.clientname.roles` claim for client-specific role mapping
- **Cookie Configuration**: Secure cookies with configurable domains and expiration
- **PKCE Support**: Enabled with S256 code challenge method

## Keycloak 25.x Configuration

### 1. Create Client Role

- Select your realm → **Clients** → Select your client (e.g., `n8n`)
- Click **Roles** tab
- Click **Create role** button
- Enter role name: `n8n-user` (or service-specific role)
- Click **Save**

### 2. Verify Default Client Roles Mapper

The default "client roles" mapper should already exist with:
- Go to **Client Scopes** → **roles** → **Mappers**
- Find the "client roles" mapper
- Verify configuration:
  - **Token Claim Name**: `resource_access.${client_id}.roles`
  - **Client ID**: (empty - allows dynamic client support)
  - **Add to ID token** and **Add to access token**: Enabled

**Note**: This creates the standard nested structure: `resource_access.clientname.roles[]`

### 3. Assign Client Role to Users

- Go to **Users** → Select user → **Role mapping** tab
- Click **Assign role**
- Filter by **Client roles**
- Select your client from dropdown (e.g., `n8n`)
- Check the client role (e.g., `n8n-user`)
- Click **Assign**

## Values Configuration

### Example Values for N8N

```yaml
oauth2Proxy:
  clientId: n8n
  allowedGroups: n8n-user
  cookieDomains: n8n.scheeps.online
  redirectUrl: https://n8n.scheeps.online/oauth2/callback
  oidcGroupsClaim: resource_access.n8n.roles  # Uses nested client roles path
  upstream:
    service: n8n
    namespace: n8n
    port: 5678
    protocol: http

secrets:
  name: n8n-auth-secret
```

## Benefits of Client Roles

- **Smaller Cookies**: Only client-specific roles in token instead of all realm roles
- **Better Isolation**: Each service has its own role namespace
- **Easier Management**: Role assignment per client
- **Enhanced Security**: Service-specific access control

## Migration from Realm Roles

If migrating from realm roles, update:
- `oidcGroupsClaim` from `realm_access_roles` to `resource_access.clientname.roles` (e.g., `resource_access.n8n.roles`)
- Create client-specific roles in Keycloak
- Reassign users to client roles instead of realm roles
- Verify the default "client roles" mapper uses `resource_access.${client_id}.roles` claim name

## Key Changes in Keycloak 25.x

- **PatternFly 5 UI**: Modern interface design
- **Centralized Permissions**: New permissions management section
- **Enhanced Role Security**: Stricter admin role assignment policies

## Deployment

1. Configure your values file with client-specific settings
2. Create the authentication secret with `client_secret` and `cookie_secret`
3. Deploy with Helm:

```bash
helm install oauth2-proxy ./oauth2-proxy -f your-values.yaml
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- A configured Keycloak realm with OIDC client
- External secrets containing client credentials

## Basic Configuration

### Chart Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | OAuth2 Proxy image repository | `quay.io/oauth2-proxy/oauth2-proxy` |
| `image.tag` | OAuth2 Proxy image tag | `v7.4.0` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `4180` |
| `service.targetPort` | Container target port | `4180` |

### OAuth2 Proxy Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `oauth2Proxy.provider` | OAuth2 provider type | `oidc` |
| `oauth2Proxy.oidcIssuerUrl` | OIDC issuer URL | `https://auth.scheeps.online/realms/scheeps` |
| `oauth2Proxy.clientId` | OIDC client ID | `""` |
| `oauth2Proxy.redirectUrl` | OAuth2 redirect URL | `""` |
| `oauth2Proxy.oidcGroupsClaim` | OIDC groups claim path | `resource_access.clientname.roles` |
| `oauth2Proxy.allowedGroups` | Allowed user groups | `""` |
| `oauth2Proxy.cookieDomains` | Cookie domains | `""` |
| `oauth2Proxy.cookieExpire` | Cookie expiration time | `4h` |
| `oauth2Proxy.pkceCodeChallenge` | Enable PKCE | `true` |
| `oauth2Proxy.pkceCodeChallengeMethod` | PKCE method | `S256` |

### Upstream Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `oauth2Proxy.upstream.service` | Upstream service name | `""` |
| `oauth2Proxy.upstream.namespace` | Upstream service namespace | `""` |
| `oauth2Proxy.upstream.port` | Upstream service port | `80` |
| `oauth2Proxy.upstream.protocol` | Upstream protocol | `http` |

### Secret Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `secrets.name` | Secret containing OAuth2 credentials | `""` |
| `secrets.clientSecretKey` | Client secret key name | `client_secret` |
| `secrets.cookieSecretKey` | Cookie secret key name | `cookie_secret` |

## Required Secrets

Create a Kubernetes secret with OAuth2 credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: n8n-auth-secret
type: Opaque
data:
  client_secret: <base64-encoded-client-secret>
  cookie_secret: <base64-encoded-cookie-secret>
```

## Troubleshooting

### Common Issues

1. **Authentication loops**: Check redirect URLs match between chart and Keycloak
2. **Group access denied**: Verify `allowedGroups` matches user's client roles and `oidcGroupsClaim` path is correct
3. **Cookie issues**: Ensure `cookieDomains` matches your application domain
4. **Wrong claim path**: Use `resource_access.clientname.roles` for nested client roles or `realm_access_roles` for realm roles

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=oauth2-proxy
```