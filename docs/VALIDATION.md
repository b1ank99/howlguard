# Validation record

Local machine: Windows x86-64; official **Godot 4.6.stable.official.89cea1439**, Compatibility renderer, NVIDIA GPU. Date: 13 October 2026 (Asia/Kuala_Lumpur).

| Check | Local result |
|---|---|
| Project import and client startup | Passed, no GDScript parser/runtime errors |
| Rules/room tests | 39 checks passed again after final implementation edits |
| Standard-budget strategy | Won ten waves; 24 shelter health remaining; 12 dogs; about 319 simulated seconds |
| Real loopback WebSocket suite | 10 checks passed: four connections, shared cash/towers, start, fresh-socket resume and malformed JSON |
| GPU render fixture | Captured actual game UI and visually inspected |
| Windows release export | Produced x86-64 executable with embedded pack; exported client and server mode both started successfully |
| Linux dedicated-server export | Produced x86-64 binary; not run on Linux locally |
| Android APK/AAB | No local Android SDK/JDK/device; not built or tested locally |
| Public WSS / carrier networks / two physical phones | Not performed; needs a deployed host and devices |
| Store submission | Not performed |

The restricted execution environment reports failure to read the Windows system certificate store. Plain loopback WebSockets still passed. **Public WSS certificate verification was not exercised here**; it must be tested in the real deployment environment without bypassing validation. Export enumeration also reports the absent Android build-tools directory; that does not stop Windows/Linux export.

The visual fixture fabricates a game snapshot solely for layout inspection. Its “Online” label is not evidence of an online hosted session. The separate transport tests exercise real sockets. The generous-funds combat fixture tests ten-wave completion; the separate balance test uses only legal commands and standard starting money.

No mobile usability review, external security audit, internet load test or accessibility certification is claimed. GitHub workflows must run after upload before their artifacts can be treated as verified CI builds.
