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
| `postgresql.username` | PostgreSQL username for PgBouncer | `postgres` |
| `postgresql.passwordSecret` | Name of Kubernetes secret containing PostgreSQL password | `postgresql-superuser` |

### Authentication Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `auth.type` | PostgreSQL authentication method | `scram-sha-256` |
| `auth.poolMode` | PgBouncer pool mode | `transaction` |
| `auth.database` | Specific database to pool (empty for all) | `""` |
| `auth.minPoolSize` | Minimum pool size per user/database pair | `5` |
| `auth.ignoreStartupParameters` | Startup parameters to ignore | `""` |
| `auth.users` | List of users with flexible authentication options | `[]` |
| `auth.externalUserlist.enabled` | Use external userlist from ConfigMap or Secret | `false` |
| `auth.externalUserlist.configMap.name` | ConfigMap name containing userlist | - |
| `auth.externalUserlist.configMap.key` | ConfigMap key containing userlist | - |
| `auth.externalUserlist.secret.name` | Secret name containing userlist | - |
| `auth.externalUserlist.secret.key` | Secret key containing userlist | - |
| `auth.userlist` | Legacy static userlist (backward compatibility) | `"<Username>" "<SCRAM Password>"` |

#### Pool Modes

- **session**: Server is released back to pool after client disconnects
- **transaction**: Server is released back to pool after transaction finishes
- **statement**: Server is released back to pool after query finishes

#### Authentication Types

- **scram-sha-256**: Secure authentication (recommended)
- **md5**: MD5-based authentication
- **plain**: Plain text authentication
- **trust**: No authentication required

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

### PostgreSQL Password Secret

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

```yaml
replicaCount: 2

postgresql:
  host: "my-postgres-service.default.svc.cluster.local"
  port: 5432
  username: "pgbouncer_user"
  passwordSecret: "my-postgres-secret"

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

## User Authentication

Version 0.3.0 introduces flexible user authentication options. You can configure users in several ways:

### Method 1: Flexible User Configuration (New in 0.3.0)

#### Secret-based Authentication

**Both Username and Password from Secrets (Recommended)**
```yaml
auth:
  type: "scram-sha-256"
  users:
    - usernameSecret:
        name: "app-credentials"
        key: "username"
      passwordSecret:
        name: "app-credentials"
        key: "password"
    - usernameSecret:
        name: "readonly-credentials"
        key: "username"
      passwordSecret:
        name: "readonly-credentials"
        key: "password"
```

**Static Username with Password from Secret**
```yaml
auth:
  type: "scram-sha-256"
  users:
    - name: "app_user"
      passwordSecret:
        name: "app-credentials"
        key: "password"
    - name: "readonly_user"
      passwordSecret:
        name: "readonly-credentials"  
        key: "password"
```

#### Plain Password Authentication (Auto-hashed)

**Username from Secret with Plain Password**
```yaml
auth:
  type: "scram-sha-256"
  users:
    - usernameSecret:
        name: "app-credentials"
        key: "username"
      password: "my_plain_password"  # Automatically converted to SCRAM-SHA-256
```

**Static Username with Plain Password**
```yaml
auth:
  type: "scram-sha-256"
  users:
    - name: "app_user"
      password: "my_plain_password"  # Automatically converted to SCRAM-SHA-256
    - name: "readonly_user"
      password: "readonly_password"
```

### Method 2: External Userlist

#### From ConfigMap
```yaml
auth:
  type: "scram-sha-256"
  externalUserlist:
    enabled: true
    configMap:
      name: "pgbouncer-users"
      key: "userlist"
```

#### From Secret
```yaml
auth:
  type: "scram-sha-256"
  externalUserlist:
    enabled: true
    secret:
      name: "pgbouncer-users-secret"
      key: "userlist"
```

### Method 3: Legacy Static Userlist (Backward Compatibility)

#### SCRAM-SHA-256 (Recommended)
```yaml
auth:
  type: "scram-sha-256"
  userlist: |
    "user1" "SCRAM-SHA-256$4096:salt$storedkey:serverkey"
    "user2" "SCRAM-SHA-256$4096:salt$storedkey:serverkey"
```

#### MD5 Authentication
```yaml
auth:
  type: "md5"
  userlist: |
    "user1" "md5hash"
    "user2" "md5hash"
```

#### Plain Text (Development Only)
```yaml
auth:
  type: "plain"
  userlist: |
    "user1" "password1"
    "user2" "password2"
```

### Required Secrets for New Authentication Methods

When using secret-based authentication, create secrets with username and/or password:

**Complete User Credentials (Recommended)**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-credentials
type: Opaque
data:
  username: <base64-encoded-username>
  password: <base64-encoded-password>
```

**Password Only**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-credentials
type: Opaque
data:
  password: <base64-encoded-password>
```

### Using Your Existing Secret

If you have a secret like `test-pg-secret` with both `username` and `password` keys:

```yaml
auth:
  type: "scram-sha-256"
  users:
    - usernameSecret:
        name: "test-pg-secret"
        key: "username"
      passwordSecret:
        name: "test-pg-secret"
        key: "password"
```

### External ConfigMap/Secret for Userlist

For external userlist, create a ConfigMap or Secret:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pgbouncer-users
data:
  userlist: |
    "user1" "SCRAM-SHA-256$4096:salt$storedkey:serverkey"
    "user2" "SCRAM-SHA-256$4096:salt$storedkey:serverkey"
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