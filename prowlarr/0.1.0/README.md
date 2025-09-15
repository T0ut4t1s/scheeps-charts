# Prowlarr Helm Chart

Prowlarr indexer manager for *arr applications in Kubernetes.

## Description

Prowlarr is an indexer manager/proxy built on the popular *arr .net/reactjs base stack to integrate with various PVR applications. It supports integration with LazyLibrarian, Lidarr, Mylar3, Radarr, Readarr, and Sonarr, providing centralized indexer management.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PostgreSQL database (recommended via PgBouncer)
- Persistent storage for configuration and media access
- Kubernetes secrets with database credentials

## Installation

```bash
helm install prowlarr ./prowlarr -n media
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `lscr.io/linuxserver/prowlarr` |
| `image.tag` | Container image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `main.count` | Number of replicas | `1` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `9696` |

### Storage Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `main.persistence.config.enabled` | Enable config storage | `true` |
| `main.persistence.config.storageClass` | Storage class for config | `longhorn-ha-2` |
| `main.persistence.config.size` | Config storage size | `2Gi` |
| `main.persistence.config.existingPvc` | Use existing PVC for config | `""` |
| `main.persistence.media.enabled` | Enable media access | `true` |
| `main.persistence.media.existingPvc` | Existing PVC for media access | `arr-media-pvc` |
| `main.persistence.media.mountPath` | Media mount path | `/media` |

### Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `db.type` | Database type | `postgresdb` |
| `db.host` | Database host | `pgbouncer.media.svc.cluster.local` |
| `db.port` | Database port | `5432` |
| `db.name` | Database name | `prowlarr` |

### Environment Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.PUID` | User ID for LinuxServer.io container | `"1000"` |
| `config.PGID` | Group ID for LinuxServer.io container | `"1000"` |
| `config.TZ` | Timezone | `Europe/London` |

### Security Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `securityContext.runAsUser` | User ID to run container | `1000` |
| `securityContext.runAsGroup` | Group ID to run container | `1000` |
| `podSecurityContext.fsGroup` | File system group ID | `1000` |
| `podSecurityContext.fsGroupChangePolicy` | FS group change policy | `"OnRootMismatch"` |

### Health Checks

| Parameter | Description | Default |
|-----------|-------------|---------|
| `livenessProbe.enabled` | Enable liveness probe | `true` |
| `livenessProbe.httpGet.path` | Liveness probe path | `/ping` |
| `livenessProbe.initialDelaySeconds` | Liveness probe initial delay | `30` |
| `readinessProbe.enabled` | Enable readiness probe | `true` |
| `readinessProbe.httpGet.path` | Readiness probe path | `/ping` |
| `readinessProbe.initialDelaySeconds` | Readiness probe initial delay | `15` |

### Resources

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `256Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `1Gi` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts | `[]` |
| `ingress.tls` | Ingress TLS configuration | `[]` |

## Required Secrets

### Database Credentials

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: prowlarr-pg-secret
  namespace: media
type: Opaque
data:
  username: <base64-encoded-database-username>
  password: <base64-encoded-database-password>
```

## PostgreSQL Integration

Prowlarr integrates seamlessly with PostgreSQL databases, providing better performance and reliability than SQLite. The chart is configured to work with PgBouncer for connection pooling.

### Database Setup

1. **Create Database**: Ensure the `prowlarr` database exists in your PostgreSQL instance
2. **Create Secret**: Create a Kubernetes secret with database credentials
3. **Configure Connection**: The chart handles database connection configuration automatically

### PgBouncer Integration

```yaml
db:
  host: pgbouncer.media.svc.cluster.local
  port: 5432
  name: prowlarr
```

## LinuxServer.io Container Specifics

This chart uses the LinuxServer.io Prowlarr container, which includes several important considerations:

### Permission Handling

The chart includes init containers to properly handle file permissions:

- **config-setup**: Prepares configuration files with database credentials
- **fix-perms**: Sets correct ownership (1000:1000) for configuration files

### User/Group Configuration

```yaml
config:
  PUID: "1000"  # User ID
  PGID: "1000"  # Group ID
  TZ: Europe/London

securityContext:
  runAsUser: 1000
  runAsGroup: 1000

podSecurityContext:
  fsGroup: 1000
  fsGroupChangePolicy: "OnRootMismatch"
```

## Example Configurations

### Basic Setup

```yaml
image:
  tag: "1.24.3"

main:
  persistence:
    config:
      storageClass: "local-path"
      size: "1Gi"

db:
  host: "postgres.database.svc.cluster.local"
  name: "prowlarr"

existingSecrets:
  database:
    name: "prowlarr-db-secret"

config:
  TZ: "America/New_York"
```

### Production Setup with Ingress

```yaml
image:
  tag: "1.24.3"
  pullPolicy: Always

main:
  persistence:
    config:
      storageClass: "fast-ssd"
      size: "5Gi"
    media:
      existingPvc: "media-storage-pvc"

resources:
  requests:
    cpu: "200m"
    memory: "512Mi"
  limits:
    cpu: "1000m"
    memory: "2Gi"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/auth-type: "basic"
    nginx.ingress.kubernetes.io/auth-secret: "prowlarr-auth"
  hosts:
    - host: prowlarr.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: prowlarr-tls
      hosts:
        - prowlarr.example.com

nodeSelector:
  kubernetes.io/arch: amd64

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - prowlarr
        topologyKey: kubernetes.io/hostname
```

### High Availability with Multiple Replicas

```yaml
main:
  count: 2

resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "2000m"
    memory: "4Gi"

affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app.kubernetes.io/name
          operator: In
          values:
          - prowlarr
      topologyKey: kubernetes.io/hostname
```

## Integration with *arr Applications

Prowlarr serves as a centralized indexer manager for various *arr applications:

### Supported Applications
- **Radarr**: Movie collection manager
- **Sonarr**: TV series collection manager  
- **Lidarr**: Music collection manager
- **Readarr**: Book/audiobook collection manager
- **Mylar3**: Comic book collection manager
- **LazyLibrarian**: Book collection manager

### Configuration
1. Deploy Prowlarr with this chart
2. Access the web UI (default port 9696)
3. Add indexers in Prowlarr
4. Configure *arr applications to sync with Prowlarr
5. Indexers will be automatically propagated to connected applications

## Monitoring and Troubleshooting

### Health Checks

The chart includes built-in health checks:
- **Liveness Probe**: `/ping` endpoint (30s delay, 30s period)
- **Readiness Probe**: `/ping` endpoint (15s delay, 15s period)

### Common Issues

1. **Permission Errors**: Ensure fsGroup and runAsUser are set correctly
2. **Database Connection**: Verify database credentials and connectivity
3. **Storage Issues**: Check PVC availability and mount permissions
4. **Resource Limits**: Monitor CPU/memory usage and adjust limits

### Logs

```bash
kubectl logs -n media deployment/prowlarr
kubectl logs -n media prowlarr-<pod-id> -c prowlarr
```

### Database Connection Test

```bash
kubectl exec -it -n media prowlarr-<pod-id> -- /bin/bash
# Inside container:
nc -zv pgbouncer.media.svc.cluster.local 5432
```

## Upgrading

### Version Upgrades

```bash
helm upgrade prowlarr ./prowlarr -n media
```

### Database Migrations

Prowlarr handles database migrations automatically on startup. Always backup your database before major version upgrades.

### Configuration Changes

Most configuration changes require a pod restart:

```bash
kubectl rollout restart deployment/prowlarr -n media
```

## Backup and Recovery

### Configuration Backup

```bash
kubectl cp media/prowlarr-<pod-id>:/config ./prowlarr-config-backup
```

### Database Backup

```bash
pg_dump -h pgbouncer.media.svc.cluster.local -U prowlarr_user prowlarr > prowlarr-db-backup.sql
```

## Security Considerations

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prowlarr-netpol
  namespace: media
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: prowlarr
  policyTypes:
  - Ingress
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
    ports:
    - protocol: TCP
      port: 5432
  - to: []
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
```

### Pod Security Standards

The chart follows Pod Security Standards with:
- Non-root user execution (UID 1000)
- Read-only root filesystem where possible
- Appropriate security contexts
- Resource limits and requests

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This chart is licensed under the Apache License 2.0.