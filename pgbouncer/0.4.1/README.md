# PgBouncer Helm Chart

A Helm chart for deploying PgBouncer connection pooler for PostgreSQL databases.

## Description

This chart deploys PgBouncer as a lightweight connection pooler for PostgreSQL. PgBouncer reduces the overhead of establishing connections to PostgreSQL by maintaining a pool of persistent connections, making it ideal for applications with many short-lived database connections or when you need to limit the number of concurrent connections to your PostgreSQL server.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- A running PostgreSQL server
- Kubernetes secret containing PostgreSQL credentials
- Optional: TLS certificates for secure connections

## Installation

```bash
helm repo add scheeps-charts https://your-repo-url
helm install my-pgbouncer scheeps-charts/pgbouncer
```

## Configuration

The following table lists the configurable parameters of the PgBouncer chart and their default values.

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | PgBouncer image repository | `bitnami/pgbouncer` |
| `image.tag` | PgBouncer image tag | `1.24.1` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `nameOverride` | Override the name of the chart | `""` |
| `fullnameOverride` | Override the full name of the release | `""` |

### PostgreSQL Connection Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.host` | PostgreSQL server hostname | `postgresql-cluster-rw.postgres-system.svc.cluster.local` |
| `postgresql.port` | PostgreSQL server port | `5432` |
| `postgresql.connectionSecret.name` | Secret name containing PostgreSQL connection credentials | `postgresql-superuser` |
| `postgresql.connectionSecret.usernameKey` | Secret key containing PostgreSQL username | `username` |
| `postgresql.connectionSecret.passwordKey` | Secret key containing PostgreSQL password | `password` |

### Authentication Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `auth.type` | PostgreSQL authentication method | `plain` |
| `auth.poolMode` | PgBouncer pool mode | `transaction` |
| `auth.minPoolSize` | Minimum pool size per user/database pair | `5` |
| `auth.ignoreStartupParameters` | Startup parameters to ignore | `""` |
| `auth.userSecret.name` | Secret name containing user authentication credentials | `pgbouncer-user-credentials` |
| `auth.userSecret.usernameKey` | Secret key containing username | `username` |
| `auth.userSecret.passwordKey` | Secret key containing password | `password` |
| `auth.userSecret.databaseKey` | Secret key containing database name | `database` |

#### Pool Modes

- **session**: Server is released back to pool after client disconnects
- **transaction**: Server is released back to pool after transaction finishes
- **statement**: Server is released back to pool after query finishes

#### Authentication Types

- **plain**: Client authenticates with a plain password stored in `auth_file`. Recommended when PgBouncer must connect to the backend using SCRAM (needs cleartext to compute SCRAM).
- **scram-sha-256**: Client authenticates with SCRAM. Requires SCRAM entries in `auth_file` and compatible tooling to provision them.
- **md5**: MD5-based client authentication. Works with MD5 entries in `auth_file`, but prevents PgBouncer from doing SCRAM to the backend if only MD5 hashes are stored.
- **trust**: No authentication required.

### TLS Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tls.enabled` | Enable TLS for PostgreSQL connections | `true` |
| `tls.serverTlsSecret` | Name of Kubernetes secret containing TLS certificates | `pgbouncer-postgres-tls` |
| `tls.sslMode` | PostgreSQL SSL mode | `verify-full` |

#### SSL Modes

- **disable**: No SSL connection
- **allow**: First try non-SSL, then SSL
- **prefer**: First try SSL, then non-SSL
- **require**: Only SSL connections
- **verify-ca**: SSL with CA verification
- **verify-full**: SSL with full certificate verification

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `5432` |

### Resource Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.requests.cpu` | CPU resource requests | `100m` |
| `resources.requests.memory` | Memory resource requests | `128Mi` |
| `resources.limits.cpu` | CPU resource limits | `200m` |
| `resources.limits.memory` | Memory resource limits | `256Mi` |

### Security Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `securityContext` | Container security context | `{}` |
| `podSecurityContext` | Pod security context | `{}` |

### Scheduling Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nodeSelector` | Node selector for pod assignment | `{}` |
| `tolerations` | Tolerations for pod assignment | `[]` |
| `affinity` | Affinity rules for pod assignment | `{}` |

## Required Secrets

This chart requires Kubernetes secrets for proper operation:

### PostgreSQL Connection Secret

**Complete PostgreSQL Credentials (Recommended)**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-superuser
type: Opaque
data:
  username: <base64-encoded-postgres-username>
  password: <base64-encoded-postgres-password>
```

**Password Only (Legacy)**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-superuser
type: Opaque
data:
  password: <base64-encoded-postgres-password>
```

### TLS Certificate Secret (when TLS is enabled)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pgbouncer-postgres-tls
type: kubernetes.io/tls
data:
  ca.crt: <base64-encoded-ca-certificate>
  tls.crt: <base64-encoded-client-certificate>
  tls.key: <base64-encoded-client-private-key>
```

## Example Values

### Basic Configuration

**Using PostgreSQL Username from Secret (Recommended)**
```yaml
replicaCount: 2

postgresql:
  host: "my-postgres-service.default.svc.cluster.local"
  port: 5432
  usernameSecret:
    name: "my-postgres-secret"
    key: "username"
  passwordSecret:
    name: "my-postgres-secret" 
    key: "password"
```

**Using Static PostgreSQL Username (Legacy)**
```yaml
replicaCount: 2

postgresql:
  host: "my-postgres-service.default.svc.cluster.local"
  port: 5432
  username: "pgbouncer_user"
  passwordSecret:
    name: "my-postgres-secret"
    key: "password"

auth:
  type: "scram-sha-256"
  poolMode: "transaction"
  minPoolSize: 10
  userlist: |
    "app_user" "SCRAM-SHA-256$4096:salt$hash:serverkey"
    "read_user" "SCRAM-SHA-256$4096:salt$hash:serverkey"

tls:
  enabled: false

resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
  requests:
    memory: "256Mi"
    cpu: "250m"
```

### High Availability Configuration

```yaml
replicaCount: 3

postgresql:
  host: "postgres-primary.database.svc.cluster.local"
  port: 5432
  username: "pgbouncer"
  passwordSecret: "pgbouncer-credentials"

auth:
  type: "scram-sha-256"
  poolMode: "session"
  minPoolSize: 20
  database: "myapp"

tls:
  enabled: true
  serverTlsSecret: "postgres-tls-certs"
  sslMode: "verify-full"

resources:
  limits:
    memory: "1Gi"
    cpu: "1000m"
  requests:
    memory: "512Mi"
    cpu: "500m"

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
            - pgbouncer
        topologyKey: kubernetes.io/hostname
```

## Multi-Connection Authentication

Version 0.4.0 introduces support for multiple simultaneous connections, allowing PgBouncer to serve multiple applications with different credentials and databases from a single instance.

### Configuration Overview

PgBouncer 0.4.0 uses a **multi-connection architecture**:

1. **Single PostgreSQL Backend**: One PostgreSQL server connection for all connections
2. **Multiple User Connections**: Each with separate credentials, users, and databases
3. **Service-Based Secrets**: Uses `<service_name>-pg-secret` naming pattern

### Multi-Connection Configuration

```yaml
# Single PostgreSQL backend connection
postgresql:
  host: "postgresql-cluster-rw.postgres-system.svc.cluster.local"
  port: 5432
  connectionSecret:
    name: "postgresql-superuser"
    usernameKey: "username"
    passwordKey: "password"

# Multiple user/database connections (3 by default)
auth:
  type: "md5"
  poolMode: "transaction"
  minPoolSize: 5
  
  connections:
    - name: "connection1"
      userSecret:
        name: "service1-pg-secret"
        usernameKey: "username"
        passwordKey: "password"
        databaseKey: "database"
    - name: "connection2"
      userSecret:
        name: "service2-pg-secret"
        usernameKey: "username"
        passwordKey: "password"
        databaseKey: "database"
    - name: "connection3"
      userSecret:
        name: "service3-pg-secret"
        usernameKey: "username"
        passwordKey: "password"
        databaseKey: "database"
```

### Required Secrets

#### PostgreSQL Backend Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-superuser
type: Opaque
data:
  username: <base64-encoded-postgres-username>
  password: <base64-encoded-postgres-password>
```

#### Connection Secrets (One per connection)

**Connection 1 Secret:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: service1-pg-secret
type: Opaque
data:
  username: <base64-encoded-app1-username>
  password: <base64-encoded-app1-password>
  database: <base64-encoded-database1-name>
```

**Connection 2 Secret:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: service2-pg-secret
type: Opaque
data:
  username: <base64-encoded-app2-username>
  password: <base64-encoded-app2-password>
  database: <base64-encoded-database2-name>
```

**Connection 3 Secret:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: service3-pg-secret
type: Opaque
data:
  username: <base64-encoded-app3-username>
  password: <base64-encoded-app3-password>
  database: <base64-encoded-database3-name>
```

### Single Connection Usage

For single connection deployments, simply define one connection:

```yaml
auth:
  connections:
    - name: "connection1"
      userSecret:
        name: "my-app-pg-secret"
        usernameKey: "username"
        passwordKey: "password"
        databaseKey: "database"
```

### Scaling Connections

To add more connections, extend the connections array:

```yaml
auth:
  connections:
    - name: "connection1"
      userSecret:
        name: "frontend-pg-secret"
        usernameKey: "username"
        passwordKey: "password"
        databaseKey: "database"
    - name: "connection2"
      userSecret:
        name: "backend-pg-secret"
        usernameKey: "username"
        passwordKey: "password"
        databaseKey: "database"
    - name: "connection3"
      userSecret:
        name: "analytics-pg-secret"
        usernameKey: "username"
        passwordKey: "password"
        databaseKey: "database"
    - name: "connection4"
      userSecret:
        name: "reporting-pg-secret"
        usernameKey: "username"
        passwordKey: "password"
        databaseKey: "database"
```

## Connection Pooling Best Practices

### Pool Mode Selection

- **Transaction mode**: Best for most web applications (default)
- **Session mode**: Use when applications require session-level features
- **Statement mode**: Maximum connection reuse but limited PostgreSQL feature support

### Pool Sizing

```yaml
auth:
  minPoolSize: 5      # Minimum connections to maintain
  # Note: maxPoolSize is configured globally in PgBouncer
```

## Monitoring and Troubleshooting

### Health Checks

The chart includes a connection test:

```bash
kubectl get pods -l app.kubernetes.io/name=pgbouncer
kubectl logs <pgbouncer-pod-name>
```

### Common Issues

1. **Connection refused**: Check PostgreSQL host and port configuration
2. **Authentication failed**: Verify userlist configuration and PostgreSQL user permissions
3. **TLS errors**: Ensure TLS certificates are valid and accessible
4. **Pool exhaustion**: Increase pool sizes or check for connection leaks in applications

### PgBouncer Stats

Connect to PgBouncer admin interface:

```bash
kubectl exec -it <pgbouncer-pod> -- psql -h localhost -p 5432 -U pgbouncer pgbouncer
```

Useful admin commands:
- `SHOW POOLS;` - Show pool information
- `SHOW CLIENTS;` - Show client connections
- `SHOW SERVERS;` - Show server connections
- `SHOW STATS;` - Show statistics

## Performance Tuning

### Resource Allocation

For high-throughput applications:

```yaml
resources:
  limits:
    memory: "2Gi"
    cpu: "2000m"
  requests:
    memory: "1Gi"
    cpu: "1000m"
```

### Connection Limits

Configure based on your PostgreSQL server capacity:

```yaml
auth:
  minPoolSize: 25      # Minimum connections per user/database
  # Total connections = minPoolSize × users × databases
```

## Integration with PostgreSQL Clusters

### CloudNativePG Integration

```yaml
postgresql:
  host: "postgres-cluster-rw.postgres-system.svc.cluster.local"
  port: 5432
  username: "pgbouncer"
  passwordSecret: "postgres-cluster-app"
```

### Patroni Integration

```yaml
postgresql:
  host: "patroni-cluster-master"
  port: 5432
  username: "pgbouncer"
  passwordSecret: "patroni-credentials"
```

## Security Considerations

### Network Policies

Restrict traffic to PgBouncer:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: pgbouncer-netpol
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: pgbouncer
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: application-namespace
    ports:
    - protocol: TCP
      port: 5432
```

### Pod Security Standards

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1001
  capabilities:
    drop:
    - ALL
```

## Migration from Direct PostgreSQL Connections

1. **Deploy PgBouncer** with minimal configuration
2. **Update application connection strings** to point to PgBouncer service
3. **Monitor connections** and adjust pool settings
4. **Scale PostgreSQL down** if connection pooling reduces resource needs

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This chart is licensed under the Apache License 2.0.
