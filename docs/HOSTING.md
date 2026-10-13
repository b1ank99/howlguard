# Internet hosting and cost

No paid service has been provisioned. The source supports internet play; the supplied default loopback address is a local development endpoint, not a live service.

## One small Linux VM

Choose an **x86-64** Linux VM near the players. A starting trial allocation is 1–2 vCPU and 2 GB RAM. This is an engineering estimate; benchmark before accepting real capacity. Allow only SSH as needed and public TCP 80/443. Keep 9080 internal. Point a domain's DNS A/AAAA records to the machine before starting Caddy; remove a broken AAAA record if IPv6 is not configured.

Install Docker Engine and the Compose plugin, upload/clone this repository, then from the project root:

```sh
export DOMAIN=play.your-real-domain.example
docker compose -f deploy/compose.yml up -d --build
docker compose -f deploy/compose.yml logs -f game caddy
```

Use an actual DNS name you control, not the example above. Caddy terminates trusted TLS and proxies WebSocket upgrade connections to the internal server. Its certificate state persists in named volumes. Every Windows and Android player enters `wss://play.your-real-domain.example`, creates/joins the same room, and requires no LAN membership or router forwarding.

The Docker image uses the pinned official Godot 4.7.2 x86-64 engine. Source and scripts are baked into the image. The game container has a read-only filesystem, a disposable home/temp directory and limited CPU/RAM. Caddy remains writable for automatic certificates. Engine binaries and base/container tags should be checksum/digest pinned and scanned before a production rollout.

Stop/rebuild when no players are in matches. Server state is memory-only: container restart erases rooms and tokens. There is no deployment or database migration automation.

## Alternative: exported server

The Linux server export is a standalone embedded-pack binary:

```sh
chmod +x howlguard-server.x86_64
BIND_ADDRESS=127.0.0.1 PORT=9080 ./howlguard-server.x86_64 --headless
```

Put a trusted TLS reverse proxy in front, configure service restart and a dedicated unprivileged user. The dedicated-server feature starts the server automatically. The Windows client executable can also run a development server with `--headless -- --server`.

## Budget (planning estimate, not a vendor quote)

Allow roughly **US$10–25/month** for an initial small VPS, plus a domain (often US$10–25/year), tax and any backup/traffic charges. Your actual provider/location and concurrency may cost more. Caddy's automatic certificate integration has no separate certificate purchase in this design. Godot has no engine royalty. Hosting is not free because players use phones; it remains an ongoing service expense even when the app is free.

Check live [provider pricing](https://www.hetzner.com/cloud/) rather than relying on this budget. Provider documentation explicitly notes [public IPs can be priced separately](https://docs.hetzner.com/cloud/servers/overview/). No provider is required by the game.

## Acceptance test for a live server

1. Connect Windows on one internet connection and two separate Android devices on carrier data or different Wi-Fi networks.
2. Create one room and join both phones. Verify roster, shared cash, wave number and identical placements.
3. Start, place from each client, upgrade/sell as owner and try a conflicting placement.
4. Toggle airplane mode for 20–40 seconds. Restore data; verify identity, towers and current wave recover. Test Wi-Fi-to-mobile handover and application background/foreground.
5. Reconnect after more than 90 seconds; expect rejection and an orphaned dog. Confirm captain transfer in the lobby.
6. Complete both a victory and defeat. Confirm all clients see the same result.
7. Monitor traffic, CPU and disconnects during a several-room soak test. Confirm TLS certificate renewal and no sensitive tokens in logs.

A static HTTP “healthy” page would not prove the game listener works. Verify an actual WebSocket handshake and room exchange. No public internet/TLS/mobile-network run has been claimed in local validation.
