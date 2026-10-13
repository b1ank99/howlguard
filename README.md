# Howlguard: Night Orchard

An original 2–4 player cooperative tower defense MVP for **Godot 4.6**, Windows and Android. A pack of dogs protects an orchard shelter from a zombie trail. Art is drawn directly from original geometric shapes; no external game assets are used.

**Status:** source and Windows/Linux exports prepared. Local simulation and real WebSocket tests pass. A public server has not been deployed and Google Play has not been submitted. Android device testing is still required. See [validation](docs/VALIDATION.md) for exactly what was verified.

## Play on Windows now

Download/extract the Windows build supplied with this project. Run `start-local-server.cmd`, then open **two separate instances** of `Howlguard.exe`.

1. Use `ws://127.0.0.1:9080` in both instances.
2. Create a room in the first instance. Enter its six-character code and join in the other.
3. The captain can start once two players are connected.
4. Select a dog card, then click/tap a grass cell. Tap a dog to inspect, upgrade or sell it.
5. Protect the shelter through ten waves. Treats, shelter health and outcomes are shared.

Two windows on one PC are a local smoke test. **Windows plus two phones on different networks use the same hosted `wss://` address**, not `127.0.0.1`. Deployment is described in [HOSTING.md](docs/HOSTING.md). You can enter the endpoint without rebuilding the client.

## Run from source

Install Godot **4.6 stable, standard edition** (not .NET), import `project.godot`, and press F6/F5. No plugins or assets need downloading.

Start the authoritative server in a separate terminal:

```sh
godot --headless --path . -- --server
```

Default: loopback port 9080. Set environment variables `PORT` and `BIND_ADDRESS` to change it. For a local multi-device test, bind `0.0.0.0`, allow TCP 9080 on a trusted network, and enter the PC's LAN address on each device. For real online play, deploy behind TLS on port 443; no player should forward a port.

## The pack and the night

| Defender | Starting cost | Pack job |
|---|---:|---|
| Echo Hound | 110 | Long reach; strips brute armor and exposes a target for 15% extra pack damage |
| Zip Corgi | 80 | Short reach and fast attacks; every third shot doubles damage |
| Frost Malamute | 140 | Area damage; slows nearby enemies by 42% |

Each dog has three levels. Upgrades improve range, damage and attack rate. Selling refunds 65% of total investment, rounded down. Cash is shared; only a dog's handler can upgrade/sell it. A handler who leaves or whose reconnect reservation expires releases the dog to the pack.

The map is a winding orchard trail on a 15×10 grass grid. Shamblers arrive from wave one, runners from wave three and armored brutes from wave five. Ten waves add enemies and health while shortening spawn intervals. A 12-second preparation period and 10-second intermissions let the pack coordinate. Start with 440 treats and 24 shelter health. Defeated enemies and completed waves fund the defense.

## Multiplayer

Godot clients speak a small versioned JSON protocol to a **headless authoritative Godot server over WebSockets**. The server simulates at 20 ticks/second and sends full room snapshots at 10/second. Clients send intentions, never damage, money, wave outcomes or enemy positions. Reliable TCP suits this slow strategy game; it can stall during packet loss, so it is not intended for twitch action.

Room codes group up to four players. Matches require two connected players to start. If a player disconnects, their random secret token reserves their identity for **90 seconds**. The client retries automatically and can also reconnect after reopening the app using its locally saved token. All-offline matches pause. The server is memory-only: a restart loses all rooms. Names are visible to room members; there are no accounts, chat, ads, payments, analytics or external SDKs.

See [architecture and protocol](docs/ARCHITECTURE.md), [hosting/cost](docs/HOSTING.md), [exports](docs/EXPORTS.md), and [store checklist](docs/RELEASE.md).

## Tests

```sh
godot --headless --path . --script res://tests/test_rules.gd
godot --headless --path . --script res://tests/test_balance.gd
godot --headless --path . --script res://tests/test_transport.gd
```

On PowerShell: `./tools/test.ps1 -Godot /path/to/godot.exe`. The transport suite binds loopback TCP 19080; this port must be available. It runs a server and independent WebSocket clients in one process using actual sockets. It does not pretend to be a physical phone test.

GitHub Actions runs these tests, exports Windows and Linux, then builds a debug Android APK. A separate manual workflow builds a signed AAB when upload-key secrets exist. Neither workflow publishes a store release or deploys a server.

## Repository

Public repository: https://github.com/b1ank99/howlguard

Builds, engine cache, Gradle-generated files and signing keys are ignored. Commit the source at the project root. Tags should identify tested source versions; increment Android version codes for each upload.

The source is provided under the rights notice in `LICENSE.md`. Godot itself and its bundled components retain their own licenses; include engine notices with redistributed binaries as described in `docs/THIRD_PARTY.md`.
