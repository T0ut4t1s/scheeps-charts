# Mosquitto MQTT Helm Chart

Eclipse Mosquitto MQTT broker for home automation messaging and IoT applications.

## Overview

This Helm chart deploys Eclipse Mosquitto MQTT broker with:
- LoadBalancer service for MQTT (1883) and WebSocket (9001) ports
- Authentication via password file generated from Kubernetes secrets
- Persistent storage for configuration and data
- Configurable logging levels
- Init container for proper password hashing and setup

## Prerequisites

- Kubernetes cluster with LoadBalancer support (MetalLB, etc.)
- Existing PersistentVolumeClaim for MQTT data storage
- External Secret containing MQTT user credentials
- Helm 3.0+

## Installation

### 1. Deploy Prerequisites

First, ensure you have the required external resources:

```yaml
# External Secret (managed outside Helm)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: mqtt-credentials
  namespace: home-automation
spec:
  secretStoreRef:
    name: your-secret-store
    kind: SecretStore
  target:
    name: mqtt-credentials
  data:
  - secretKey: ha-password
    remoteRef:
      key: mqtt-credentials
      property: homeassistant_password
  - secretKey: nodered-password
    remoteRef:
      key: mqtt-credentials  
      property: nodered_password
  - secretKey: frigate-password
    remoteRef:
      key: mqtt-credentials
      property: frigate_password
```

```yaml
# PVC (managed outside Helm)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mqtt-config-pvc
  namespace: home-automation
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn-ha-2
  resources:
    requests:
      storage: 2Gi
```

### 2. Install the Chart

```bash
helm install mqtt ./mosquitto-mqtt \
  --namespace home-automation \
  --create-namespace
```

### 3. Custom Installation

```bash
# With custom values
helm install mqtt ./mosquitto-mqtt \
  --namespace home-automation \
  --values custom-values.yaml
```

## Configuration

The following table lists the configurable parameters and their default values.

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Mosquitto image repository | `eclipse-mosquitto` |
| `image.tag` | Mosquitto image tag | `""` (uses Chart appVersion) |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `LoadBalancer` |
| `service.mqtt.port` | MQTT service port | `1883` |
| `service.websocket.enabled` | Enable WebSocket listener | `true` |
| `service.websocket.port` | WebSocket service port | `9001` |
| `loadBalancerIP` | Static LoadBalancer IP | `""` |

### MQTT Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mqtt.logging.connectionMessages` | Log connection/disconnection messages | `false` |
| `mqtt.logging.logTypes` | Array of log types to enable | `["error", "warning", "notice", "information"]` |
| `mqtt.users.homeassistant.enabled` | Enable homeassistant user | `true` |
| `mqtt.users.nodered.enabled` | Enable nodered user | `true` |
| `mqtt.users.frigate.enabled` | Enable frigate user | `true` |

### Storage Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.existingClaim` | Name of existing PVC | `"mqtt-config-pvc"` |
| `persistence.mountPath` | Mount path for persistence | `"/mosquitto"` |

### Secret Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `secrets.credentialsSecret` | Name of secret containing user credentials | `"mqtt-credentials"` |
| `secrets.keys.homeassistantPassword` | Key for homeassistant password | `"ha-password"` |
| `secrets.keys.noderedPassword` | Key for nodered password | `"nodered-password"` |
| `secrets.keys.frigatePassword` | Key for frigate password | `"frigate-password"` |

## Example Values

```yaml
# values.yaml
service:
  type: LoadBalancer
  loadBalancerIP: "192.168.1.100"

mqtt:
  logging:
    connectionMessages: false
    logTypes:
      - error
      - warning
      - information
      - subscribe
      - unsubscribe

  users:
    homeassistant:
      enabled: true
    nodered:
      enabled: true
    frigate:
      enabled: false

secrets:
  credentialsSecret: "my-mqtt-credentials"
  keys:
    homeassistantPassword: "homeassistant-pass"
    noderedPassword: "nodered-pass"

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

## MQTT Client Configuration

Once deployed, configure your MQTT clients to connect:

### Connection Details
- **Host**: LoadBalancer IP or service DNS name
- **Port**: 1883 (MQTT) or 9001 (WebSocket)
- **Authentication**: Username/password from your External Secret

### Home Assistant
```yaml
# configuration.yaml
mqtt:
  broker: <loadbalancer-ip>
  port: 1883
  username: homeassistant
  password: <password-from-secret>
```

### Node-RED
Configure MQTT nodes with:
- Server: `<loadbalancer-ip>:1883`
- Username: `nodered`
- Password: `<password-from-secret>`

## Troubleshooting

### Common Issues

1. **Pod stuck in Init state**
   - Check External Secret is deployed and contains expected keys
   - Verify secret keys match `secrets.keys` values in chart

2. **Connection authentication failures**
   - Ensure password file is properly generated with correct hashing
   - Check init container logs: `kubectl logs <pod> -c setup-mosquitto`

3. **LoadBalancer pending**
   - Verify MetalLB or cloud LoadBalancer is configured
   - Check service annotations for provider-specific config

### Useful Commands

```bash
# Check pod status
kubectl get pods -n home-automation

# View logs
kubectl logs deployment/mqtt-mosquitto-mqtt -n home-automation

# Check service
kubectl get svc mqtt-mosquitto-mqtt -n home-automation

# Test MQTT connection
mosquitto_pub -h <loadbalancer-ip> -t test/topic -m "hello" -u homeassistant -P <password>
```

## Upgrading

```bash
helm upgrade mqtt ./mosquitto-mqtt \
  --namespace home-automation \
  --values values.yaml
```

## Uninstallation

```bash
helm uninstall mqtt --namespace home-automation
```

**Note**: This will not delete the PVC or External Secret as they are managed outside of Helm.

## License

This chart is licensed under the Apache 2.0 License.

## Contributing

Contributions are welcome! Please submit issues and pull requests to the chart repository.