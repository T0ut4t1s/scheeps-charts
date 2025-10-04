# Scheeps Helm Chart Patterns

This document summarizes the common patterns and structure used across our custom Helm charts in the scheeps_charts repository.

## Chart Structure Overview

Our charts follow a consistent structure with the following key components:

```
chart-name/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── questions.yaml      # Rancher UI configuration (where applicable)
├── README.md          # Chart documentation (where applicable)
└── templates/
    ├── _helpers.tpl    # Template helpers
    ├── deployment.yaml # Main application deployment
    ├── service.yaml    # Kubernetes service
    ├── pvc.yaml       # Persistent volume claims (where needed)
    └── serviceaccount.yaml # Service account (where needed)
```

## Example: OAuth2-Proxy Chart (Comprehensive Pattern)

The `oauth2-proxy/0.2.1` chart demonstrates our most mature pattern:

### Chart.yaml Structure
```yaml
apiVersion: v2
name: oauth2-proxy
description: OAuth2 Proxy for OIDC authentication with Keycloak integration
type: application
version: 0.2.1
appVersion: v7.12.0
maintainers:
  - name: theunis
keywords:
  - oauth2
  - proxy
  - authentication
  - oidc
  - keycloak
home: https://github.com/oauth2-proxy/oauth2-proxy
sources:
  - https://github.com/oauth2-proxy/oauth2-proxy
```

### Key Values.yaml Patterns

**Image Configuration:**
```yaml
image:
  repository: quay.io/oauth2-proxy/oauth2-proxy
  pullPolicy: IfNotPresent
  tag: ""  # Uses appVersion from Chart.yaml if empty
```

**Service Configuration:**
```yaml
service:
  type: ClusterIP
  port: 4180
  targetPort: 4180
  name: http
```

**Application-Specific Configuration:**
```yaml
oauth2Proxy:
  provider: "oidc"
  oidcIssuerUrl: "https://auth.scheeps.online/realms/scheeps"
  clientId: "" # Application-specific
  redirectUrl: "" # Application-specific
  upstream:
    service: ""
    namespace: ""
    port: 80
    protocol: "http"
```

**Secret Management:**
```yaml
secrets:
  name: "" # e.g. vlan-auth-secret
  clientSecretKey: "client_secret"
  cookieSecretKey: "cookie_secret"
```

### Rancher Questions Integration

Our charts include `questions.yaml` for Rancher UI integration:

```yaml
categories:
- Authentication
- Security
- Proxy

questions:
- variable: replicaCount
  default: 2
  description: "Number of OAuth2 Proxy replicas"
  type: int
  label: Replica Count
  group: "Basic Configuration"

- variable: oauth2Proxy.clientId
  description: "OAuth2 client ID for the application"
  type: string
  label: Client ID
  group: "OAuth2 Provider"
  required: true
```

## Example: Sonarr Chart (Media Application Pattern)

The `sonarr/0.1.1` chart shows our pattern for media applications:

### Media-Specific Values
```yaml
main:
  count: 1
  persistence:
    config:
      enabled: true
      storageClass: longhorn-ha-2
      size: 2Gi
    media:
      enabled: true
      existingPvc: arr-media-pvc
      mountPath: /media

db:
  type: postgresdb
  host: pgbouncer.media.svc.cluster.local
  port: 5432
  name: sonarr

config:
  PUID: "1000"
  PGID: "1000"
  TZ: Europe/London

existingSecrets:
  database:
    name: sonarr-pg-secret
    username: username
    password: password

namespaceOverride: media
```

## Common Patterns

### 1. Secret Management
- External secrets follow naming pattern: `{service}-{type}-secret`
- Database secrets: `{service}-pg-secret`
- Auth secrets: `{service}-auth-secret`

### 2. Storage Patterns
- Configuration: Longhorn storage classes (`longhorn-ha-1`, `longhorn-ha-2`)
- Media: Shared PVCs (`arr-media-pvc`)
- Namespace-specific storage when needed

### 3. Database Integration
- PgBouncer connection pooling: `pgbouncer.{namespace}.svc.cluster.local`
- Database credentials from external secrets
- Environment variable patterns: `{APP}__POSTGRES__{CONFIG}`

### 4. Security Context
```yaml
securityContext:
  runAsNonRoot: false
  runAsUser: 1000
  runAsGroup: 1000
  readOnlyRootFilesystem: false
podSecurityContext:
  fsGroup: 1000
  supplementalGroups:
    - 988  # NFS permissions group
```

### 5. Health Checks
```yaml
livenessProbe:
  enabled: true
  httpGet:
    path: /ping
    port: 8989
  initialDelaySeconds: 30
  periodSeconds: 30

readinessProbe:
  enabled: true
  httpGet:
    path: /ping
    port: 8989
  initialDelaySeconds: 15
  periodSeconds: 15
```

## Environment Integration

### Keycloak Authentication
- OIDC issuer: `https://auth.scheeps.online/realms/scheeps`
- OAuth2 proxy pattern for web applications
- Client-specific configuration per application

### Network Architecture
- No traditional Ingress resources
- LoadBalancer services with MetalLB
- Cloudflare Tunnel integration
- Internal service communication via cluster DNS

### Storage Classes
- `longhorn-ha-1/2`: High availability with retention
- `fast-1/2`: Performance storage
- `cache-1/2`: Temporary storage
- `unas-nfs`: Media storage

This pattern ensures consistency across all applications while maintaining flexibility for specific requirements.