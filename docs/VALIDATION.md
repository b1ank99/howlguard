# Validation record

Local machine: Windows x86-64; official **Godot 4.7.2.stable.official.ed1daf0bf**, Compatibility renderer, NVIDIA GPU. Date: 13 October 2026 (Asia/Kuala_Lumpur). All four suites were rerun successfully after upgrading from 4.6 for supported Android API 36 exports.

| Check | Local result |
|---|---|
| Project import and client startup | Passed, no GDScript parser/runtime errors |
| Rules/room tests | 39 checks passed again after final implementation edits |
| Standard-budget strategy | Won ten waves; 24 shelter health remaining; 12 dogs; about 319 simulated seconds |
| Real loopback WebSocket suite | 10 checks passed: four connections, shared cash/towers, start, fresh-socket resume and malformed JSON |
| Actual client networking | 10 checks: three shipped client nodes, automatic reconnect, preserved ownership and acknowledged room leave |
| GPU render fixture | Captured actual game UI and visually inspected |
| Windows release export | Produced x86-64 executable with embedded pack; exported client and server mode both started successfully |
| Linux dedicated-server export | Produced x86-64 binary; not run on Linux locally |
| Android APK/AAB | No local Android SDK/JDK/device; not built or tested locally |
| GitHub CI build | [Run 4](https://github.com/b1ank99/howlguard/actions/runs/38350317855) succeeded: all four suites, Windows export, Linux server startup and Android debug APK export |
| Public WSS / carrier networks / two physical phones | Not performed; needs a deployed host and devices |
| Store submission | Not performed |

The restricted execution environment reports failure to read the Windows system certificate store. Plain loopback WebSockets still passed. **Public WSS certificate verification was not exercised here**; it must be tested in the real deployment environment without bypassing validation. Export enumeration also reports the absent Android build-tools directory; that does not stop Windows/Linux export.

The visual fixture fabricates a game snapshot solely for layout inspection. Its “Online” label is not evidence of an online hosted session. The separate transport tests exercise real sockets. The generous-funds combat fixture tests ten-wave completion; the separate balance test uses only legal commands and standard starting money.

The verified Android APK is available in the successful run's `howlguard-android-debug` artifact. The automated browser download stalled, so no local APK copy or separate manifest/device inspection is claimed. The configured export targets API 36; verify the final manifest on a device/with Android tools before release. No signed release AAB was generated because an owner-controlled upload key has not been supplied.

No mobile usability review, external security audit, internet load test or accessibility certification is claimed. The tested CI source commit is `dc32ccd`; subsequent documentation-only commits do not change the tested implementation.
