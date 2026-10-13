# Server authority and protocol

```text
Windows client ─┐
Android phone ─┼─ WSS / TCP 443 ─ Caddy TLS proxy ─ Godot server :9080
Android phone ─┘                                └─ in-memory rooms
```

`scripts/rules.gd` owns simulation and validation. `rooms.gd` manages room membership and secret resume tokens. `server.gd` accepts WebSocket streams with `TCPServer` / `WebSocketPeer`. `network.gd` is the common Windows/Android client transport. `main.gd` and `board.gd` handle the UI and original procedural art. No Godot high-level RPC peer IDs or NAT traversal are needed because clients initiate outbound TCP connections.

## Wire contract, version 1

Messages are UTF-8 JSON objects in text WebSocket frames. Requests contain `op`. Membership requests also contain `version: 1`. Normal traffic looks like:

```json
{"op":"create","version":1,"name":"Riley"}
{"op":"join","version":1,"name":"Sam","code":"ABC123"}
{"op":"resume","version":1,"code":"ABC123","token":"secret from joined response"}
{"op":"start"}
{"op":"place","kind":"echo","x":6,"y":4}
{"op":"upgrade","id":1}
{"op":"sell","id":1}
{"op":"ping"}
{"op":"leave"}
```

`joined` returns `code`, a random player `id`, and a 192-bit random `token`. The token is sent only to that player's connection; it never appears in shared snapshots. Keep tokens out of logs, URLs and support screenshots. Use trusted WSS in public deployments. Plain WS is only for trusted development.

`state` carries `code`, captain ID, visible roster, cash, shelter lives, phase, wave, preparation countdown, server tick, towers, enemies and cosmetic hit effects. A full snapshot restores a newly resumed client. A response is either `{"op":"ok"}` or `{"error":"human-readable reason"}`. `pong` is an application heartbeat. The optional `hello` request verifies the protocol version. No client timestamp or economy mutation is trusted.

## Invariants

- Two connected players minimum to start; up to four reserved/connected seats.
- Only the captain starts a lobby. On disconnect, captain role moves to a connected player, including the first resumed player if the whole lobby was offline.
- Joining a started game is rejected except authenticated resume into an existing reserved seat.
- Grass placements require integral, finite, in-bounds coordinates and an unoccupied cell away from the trail. Invalid commands leave cash unchanged.
- Shared economy mutations run serially on the server tick thread. Simultaneous placements cannot both acquire a cell. Damage, kill rewards and leaks run only on the server.
- Upgrade and sale ownership is checked on the server; orphan dogs can be managed by anyone.
- Resume tokens cannot take over an already connected player. Reservations expire after 90 server seconds. The game pauses when nobody is online; reservations still expire.
- An empty room is removed. A room without active users also has a 10-minute idle cap. Connected finished rooms remain until clients leave.

## Network boundaries

The transport admits at most 128 peers and 32 rooms; each room allows 60 towers. Commands are limited to 4 KiB and text frames. Each socket has a token bucket of 20 commands, replenished at eight/second. Silent peers time out after 45 seconds; handshake timeout is ten seconds. Slow output consumers are disconnected when the queue exceeds 128 KiB. The app sends a ping every ten seconds and reconnects after a 25-second receive stall, using up to twelve retries with capped backoff.

These are starter limits, not an audited DDoS defense. A reconnect token is a bearer credential stored in `user://connection.cfg` using the OS application directory. There is no account recovery, matchmaking, invite authorization beyond knowledge of the room code, platform attestation or persistent game database. Room codes are not passwords. Network deployment must use a trusted TLS certificate; do not disable certificate validation.

Simulation uses a 0.05-second fixed step with a capped accumulated frame delta. Severe server overload slows match time. Full JSON snapshots trade simplicity and reliable resume for bandwidth; client drawings smooth positions between received snapshots but do not simulate combat. Cosmetic hit effects may be dropped between snapshots. No input prediction, rewind, replay, host migration across machines or server-crash recovery is implemented.

## Before increasing capacity

Measure CPU, bandwidth and latency at the intended player count. Do not route an existing room across multiple server processes: use session affinity/room-to-server mapping first. Add metrics, IP-level abuse protection, a graceful drain mode, structured redacted logs, persisted snapshots and admission controls. Test real carrier networks and TLS proxy upgrades. None of these scale features is claimed complete in the MVP.
