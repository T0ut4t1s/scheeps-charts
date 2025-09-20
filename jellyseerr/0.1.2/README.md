# Jellyseerr Helm Chart

A Helm chart for deploying Jellyseerr, a request management application for Jellyfin media servers.

## Description

Jellyseerr is a fork of Overseerr built to work with Jellyfin media servers. It allows users to request movies and TV shows, which can then be automatically downloaded and added to your Jellyfin library.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PostgreSQL database (recommended) or SQLite (default)
- Persistent storage for configuration

## Installation

1. Clone or download this chart
2. Configure your values (see Configuration section)
3. Install the chart:

```bash
helm install jellyseerr ./jellyseerr-0.1.2 -n media
```

## Configuration

### Database Configuration

This chart supports both PostgreSQL (recommended) and SQLite databases.

#### PostgreSQL (Recommended)

For PostgreSQL, configure the following in your `values.yaml`:

```yaml
db:
  type: postgresdb
  host: your-postgres-host.example.com
  port: 5432
  name: jellyseerr

existingSecrets:
  database:
    name: jellyseerr-pg-secret
    username: username
    password: password
```

Create a secret with your database credentials:

```bash
kubectl create secret generic jellyseerr-pg-secret \
  --from-literal=username=your_db_user \
  --from-literal=password=your_db_password \
  -n media
```

The following environment variables are configured for PostgreSQL:
- `DB_TYPE=postgres`
- `DB_HOST` - Database hostname
- `DB_PORT` - Database port (default: 5432)
- `DB_NAME` - Database name
- `DB_USER` - Database username (from secret)
- `DB_PASS` - Database password (from secret)
- `DB_LOG_QUERIES=false` - Disable query logging (optional)

#### SQLite (Default)

If no database configuration is provided, Jellyseerr will use SQLite with data stored in the persistent volume.

### Storage Configuration

Configure persistent storage for Jellyseerr configuration:

```yaml
main:
  persistence:
    config:
      enabled: true
      storageClass: longhorn-ha-2
      size: 2Gi
      # Use existing PVC (optional)
      existingPvc: ""
```

### Service Configuration

```yaml
service:
  type: ClusterIP
  port: 5055
```

### Resource Limits

```yaml
resources:
  requests:
    memory: 256Mi
    cpu: 100m
  limits:
    memory: 1Gi
    cpu: 500m
```

### Health Checks

The chart includes liveness and readiness probes:

```yaml
livenessProbe:
  enabled: true
  httpGet:
    path: /api/v1/status
    port: 5055
  initialDelaySeconds: 30
  periodSeconds: 30

readinessProbe:
  enabled: true
  httpGet:
    path: /api/v1/status
    port: 5055
  initialDelaySeconds: 15
  periodSeconds: 15
```

### Security Context

```yaml
securityContext:
  runAsNonRoot: false
  runAsUser: 1000
  runAsGroup: 1000
  readOnlyRootFilesystem: false

podSecurityContext:
  fsGroup: 1000
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `image.repository` | string | `"fallenbagel/jellyseerr"` | Jellyseerr container image repository |
| `image.tag` | string | `""` | Overrides the image tag (default is Chart.appVersion) |
| `image.pullPolicy` | string | `"IfNotPresent"` | Image pull policy |
| `main.count` | int | `1` | Number of replicas |
| `main.persistence.config.enabled` | bool | `true` | Enable persistent storage for config |
| `main.persistence.config.storageClass` | string | `"longhorn-ha-2"` | Storage class for config PVC |
| `main.persistence.config.size` | string | `"2Gi"` | Size of config PVC |
| `db.type` | string | `"postgresdb"` | Database type (postgresdb or sqlite) |
| `db.host` | string | `"pgbouncer.media.svc.cluster.local"` | Database hostname |
| `db.port` | int | `5432` | Database port |
| `db.name` | string | `"jellyseerr"` | Database name |
| `config.LOG_LEVEL` | string | `"info"` | Log level |
| `config.TZ` | string | `"Europe/London"` | Timezone |
| `namespaceOverride` | string | `"media"` | Override namespace |

## Upgrading

### From 0.1.1 to 0.1.2

Version 0.1.2 fixes PostgreSQL database connectivity by correcting environment variable names:
- `DATABASE_*` variables changed to `DB_*` format
- Added `DB_LOG_QUERIES` environment variable

No manual intervention required - the upgrade will automatically apply the correct environment variables.

## Troubleshooting

### Database Connection Issues

1. Verify your database secret exists and contains correct credentials:
   ```bash
   kubectl get secret jellyseerr-pg-secret -n media -o yaml
   ```

2. Check pod logs for database connection errors:
   ```bash
   kubectl logs -n media deployment/jellyseerr
   ```

3. Verify database connectivity from within the cluster:
   ```bash
   kubectl run -it --rm debug --image=postgres:alpine --restart=Never -- psql -h your-db-host -U your-user -d jellyseerr
   ```

### Storage Issues

1. Check PVC status:
   ```bash
   kubectl get pvc -n media
   ```

2. Verify storage class is available:
   ```bash
   kubectl get storageclass
   ```

## Version History

- **0.1.2** - Fixed PostgreSQL environment variables, added DB_LOG_QUERIES
- **0.1.1** - Initial release with PostgreSQL support

## Support

For issues with this Helm chart, please check:
1. Jellyseerr documentation
2. Your database connectivity
3. Kubernetes cluster logs
4. Storage class availability