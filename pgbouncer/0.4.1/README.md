# PgBouncer Helm Chart

PgBouncer connection pooler for PostgreSQL databases in Kubernetes.

## Description

Lightweight connection pooler that reduces PostgreSQL connection overhead by maintaining persistent connection pools. Ideal for applications with many short-lived connections or when limiting concurrent database connections.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PostgreSQL server
- Kubernetes secrets with database credentials

## Installation

```bash
helm install my-pgbouncer ./pgbouncer
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `bitnami/pgbouncer` |
| `image.tag` | Image tag | `1.24.1` |

### PostgreSQL Connection

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.host` | PostgreSQL hostname | `postgresql-cluster-rw.postgres-system.svc.cluster.local` |
| `postgresql.port` | PostgreSQL port | `5432` |
| `postgresql.connectionSecret.name` | Secret name for PostgreSQL credentials | `postgresql-superuser` |

### Pool Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pool.mode` | Pool mode (session/transaction/statement) | `transaction` |
| `pool.minPoolSize` | Minimum pool size | `5` |
| `pool.defaultPoolSize` | Default pool size | `25` |
| `pool.reservePoolSize` | Reserve pool size | `0` |
| `pool.maxClientConn` | Maximum client connections | `100` |
| `pool.serverIdleTimeout` | Server idle timeout (seconds) | `600` |
| `pool.serverLifetime` | Server lifetime (seconds) | `3600` |

### Authentication

| Parameter | Description | Default |
|-----------|-------------|---------|
| `auth.type` | Authentication method (plain/md5/scram-sha-256/trust) | `plain` |

### Multi-Connection Setup

Configure multiple application connections:

```yaml
auth:
  connection1Enabled: true
  connection1Name: "app1"
  connection1SecretName: "app1-pg-secret"
  
  connection2Enabled: true
  connection2Name: "app2"
  connection2SecretName: "app2-pg-secret"
```

Each connection requires a secret with `username`, `password`, and `database` keys.

### TLS Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tls.enabled` | Enable TLS | `true` |
| `tls.sslMode` | SSL mode | `verify-full` |
| `tls.serverTlsSecret` | TLS secret name | `pgbouncer-postgres-tls` |

### Resources

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |
| `resources.limits.cpu` | CPU limit | `200m` |
| `resources.limits.memory` | Memory limit | `256Mi` |

## Required Secrets

### PostgreSQL Backend
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-superuser
data:
  username: <base64-username>
  password: <base64-password>
```

### Application Connections
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app1-pg-secret
data:
  username: <base64-app-username>
  password: <base64-app-password>
  database: <base64-database-name>
```

## Example Configuration

```yaml
replicaCount: 2

postgresql:
  host: "postgres.default.svc.cluster.local"
  connectionSecret:
    name: "postgres-credentials"

pool:
  mode: "transaction"
  minPoolSize: 10
  defaultPoolSize: 50
  maxClientConn: 200

auth:
  type: "scram-sha-256"
  connection1Enabled: true
  connection1Name: "frontend"
  connection1SecretName: "frontend-pg-secret"
  connection2Enabled: true
  connection2Name: "backend" 
  connection2SecretName: "backend-pg-secret"

tls:
  enabled: true
  sslMode: "require"

resources:
  requests:
    cpu: "200m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

## Pool Modes

- **transaction**: Server released after transaction (recommended)
- **session**: Server released after client disconnect
- **statement**: Server released after each query

## Authentication Types

- **plain**: Plain password (recommended for SCRAM backends)
- **scram-sha-256**: SCRAM authentication
- **md5**: MD5 authentication
- **trust**: No authentication

## Monitoring

Check status:
```bash
kubectl logs <pgbouncer-pod>
kubectl exec -it <pgbouncer-pod> -- psql -h localhost -p 5432 -U pgbouncer pgbouncer
```

Admin commands:
- `SHOW POOLS;` - Pool information
- `SHOW CLIENTS;` - Client connections
- `SHOW SERVERS;` - Server connections
- `SHOW STATS;` - Statistics

## Troubleshooting

1. **Connection refused**: Check PostgreSQL host/port
2. **Auth failed**: Verify credentials and permissions
3. **TLS errors**: Check certificate validity
4. **Pool exhaustion**: Increase pool sizes

## License

Apache License 2.0