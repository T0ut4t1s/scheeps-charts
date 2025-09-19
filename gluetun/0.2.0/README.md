# Gluetun VPN Helm Chart

A Helm chart for deploying [Gluetun](https://github.com/qdm12/gluetun) VPN proxy with HTTP/SOCKS support, kill-switch, and Prometheus monitoring.

## Overview

Gluetun is a lightweight VPN client in a Docker container that supports multiple VPN providers (NordVPN, ExpressVPN, Surfshark, and many others). This Helm chart deploys Gluetun with HTTP and SOCKS proxy capabilities, making it easy to route traffic through a VPN connection in Kubernetes environments.

## Features

- ✅ **Multi-provider VPN support** - NordVPN, ExpressVPN, Surfshark, Mullvad, ProtonVPN, and more
- ✅ **HTTP & SOCKS proxy** - Built-in proxy servers for routing traffic
- ✅ **VPN Kill Switch** - Firewall that blocks non-VPN traffic  
- ✅ **Server Categories** - Filter servers by type (P2P, streaming, standard)
- ✅ **Health Monitoring** - Prometheus metrics and health checks
- ✅ **Rancher UI Support** - User-friendly configuration through Rancher questions
- ✅ **Configurable networking** - Support for custom subnets and firewall rules

## Quick Start

### Prerequisites

- Kubernetes cluster
- Helm 3.x
- VPN provider credentials

### Installation

1. **Create VPN credentials secret:**
```bash
kubectl create secret generic gluetun-vpn-secret \
  --from-literal=OPENVPN_USER="your-username" \
  --from-literal=OPENVPN_PASSWORD="your-password" \
  -n vpn-gateway
```

2. **Install the chart:**
```bash
helm install gluetun ./0.2.0 -n vpn-gateway --create-namespace
```

3. **Access proxies:**
- HTTP proxy: `<service-ip>:8888`
- SOCKS proxy: `<service-ip>:1080`

## Configuration

### Basic VPN Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `vpn.provider` | VPN service provider | `nordvpn` |
| `vpn.type` | VPN connection type (openvpn/wireguard) | `openvpn` |
| `vpn.country` | VPN server country | `"United Kingdom"` |
| `vpn.serverCategories` | Server categories (P2P, streaming, etc.) | `""` |
| `vpn.timezone` | Container timezone | `Europe/London` |

### Proxy Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `proxy.httpPort` | HTTP proxy listening port | `8888` |
| `proxy.socksPort` | SOCKS proxy listening port | `1080` |

### Firewall/Kill Switch

| Parameter | Description | Default |
|-----------|-------------|---------|
| `vpn.firewall.enabled` | Enable VPN kill switch | `true` |
| `vpn.firewall.outboundSubnets` | Allowed local subnets | `[192.168.100.0/24, ...]` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.enabled` | Enable Kubernetes service | `true` |
| `service.type` | Service type | `LoadBalancer` |

## VPN Providers

Supported VPN providers include:

- **NordVPN** - `nordvpn`
- **ExpressVPN** - `expressvpn` 
- **Surfshark** - `surfshark`
- **Mullvad** - `mullvad`
- **ProtonVPN** - `protonvpn`
- **Private Internet Access** - `pia`
- **CyberGhost** - `cyberghost`
- **Windscribe** - `windscribe`
- **Custom** - `custom` (for custom OpenVPN configs)

## Server Categories

Use the `serverCategories` parameter to filter servers by purpose:

- **P2P** - Optimized for torrenting/file sharing
- **Standard** - General purpose servers
- **Streaming** - Optimized for video streaming
- **Double VPN** - Enhanced privacy (provider dependent)

Example:
```yaml
vpn:
  serverCategories: "P2P,Standard"
```

## Advanced Configuration

### Custom OpenVPN Configuration

```yaml
vpn:
  provider: custom
  openvpn:
    customConfig: true
    configFile: |
      # Your custom OpenVPN config here
      remote vpn.example.com 1194 udp
      # ... additional config
```

### Prometheus Monitoring

```yaml
prometheus:
  enabled: true
  port: 8000
  path: "/v1/health"
  labels:
    release: rancher-monitoring
```

### Resource Limits

```yaml
resources:
  limits:
    memory: "256Mi"
    cpu: "200m"
    squat.ai/tun: 1  # Required for TUN device
  requests:
    memory: "128Mi"
    cpu: "100m"
```

## Security Considerations

1. **Credentials Storage**: Always use Kubernetes secrets for VPN credentials
2. **Network Policies**: Consider implementing network policies to restrict traffic
3. **Kill Switch**: Keep firewall enabled to prevent IP leaks
4. **Updates**: Regularly update to the latest Gluetun version

## Troubleshooting

### Common Issues

**Connection Problems:**
- Verify VPN credentials in the secret
- Check if the selected country/server is available
- Review Gluetun logs: `kubectl logs deployment/gluetun -n vpn-gateway`

**Proxy Not Working:**
- Ensure firewall allows your subnet in `outboundSubnets`
- Verify service is exposing the correct ports
- Check if pods are ready: `kubectl get pods -n vpn-gateway`

**Health Check Failures:**
- VPN connection may be down
- Check provider status and server availability
- Verify credentials are correct

### Useful Commands

```bash
# Check deployment status
kubectl get deployment gluetun -n vpn-gateway

# View logs
kubectl logs -f deployment/gluetun -n vpn-gateway

# Check service endpoints
kubectl get svc gluetun -n vpn-gateway

# Test HTTP proxy
curl -x <service-ip>:8888 ifconfig.me

# Test SOCKS proxy  
curl --socks5 <service-ip>:1080 ifconfig.me
```

## Upgrading

### From v0.1.x to v0.2.0

Version 0.2.0 adds support for server categories and Rancher questions. No breaking changes to existing configurations.

```bash
helm upgrade gluetun ./0.2.0 -n vpn-gateway
```

## Development

### Testing Changes

```bash
# Validate templates
helm template gluetun ./0.2.0

# Dry run installation
helm install gluetun ./0.2.0 --dry-run -n vpn-gateway

# Lint chart
helm lint ./0.2.0
```

## License

This Helm chart is provided under the same license as Gluetun. See the [Gluetun repository](https://github.com/qdm12/gluetun) for details.

## Links

- [Gluetun GitHub](https://github.com/qdm12/gluetun)
- [Gluetun Documentation](https://github.com/qdm12/gluetun/wiki)
- [VPN Provider Setup Guides](https://github.com/qdm12/gluetun/wiki/VPN-providers)