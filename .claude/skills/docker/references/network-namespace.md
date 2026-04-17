# Network Namespace Sharing (Sidecar)

`network_mode: "service:<name>"` makes a container
join another container's network namespace. They
share the same IP address, network interfaces, and
loopback — they are network-identical processes.

The canonical use case is a VPN or proxy sidecar:
one container owns the network (VPN tunnel,
WireGuard, Tor exit), and the app routes all its
traffic through it by sharing its namespace.

```yaml
services:
  vpn:
    image: ghcr.io/qdm12/gluetun
    cap_add: [NET_ADMIN]
    devices: [/dev/net/tun]
    ports:
      - "127.0.0.1:8080:8080"  # app's port here
    healthcheck:
      test: ["CMD", "/gluetun-entrypoint", "healthcheck"]
      interval: 5s
      retries: 5

  app:
    image: myapp
    network_mode: "service:vpn"
    depends_on:
      vpn:
        condition: service_healthy
```

Key rules:

- **Port publishing goes on the namespace owner
  (`vpn`), not the sidecar (`app`).** The sidecar
  has no independent network interface to publish
  from.
- **`depends_on: condition: service_healthy` is
  required.** Without it, `app` starts before the
  tunnel is up and traffic escapes unencrypted.
- **Other Compose services cannot reach `app`
  directly** — they must address `vpn` by service
  name, and traffic arrives at `app` via the shared
  namespace.
- **Within the shared namespace, containers
  communicate via `localhost`.**
- `network_mode: "service:<name>"` and `networks:`
  are mutually exclusive on the same service.
