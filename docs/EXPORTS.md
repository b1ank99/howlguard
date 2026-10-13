# Export builds

Use Godot **4.7.2 stable** and matching **4.7.2.stable export templates**. Download them through the Godot editor or the official release. Create the output folders before command-line exports.

## Windows x86-64

```sh
godot --headless --editor --import --quit
godot --headless --export-release "Windows Desktop" build/windows/Howlguard.exe
```

The preset embeds the game pack in the executable. Ship the console wrapper, local server launcher, engine notices and instructions with it. The build is not Authenticode signed; reputation warnings may appear. Obtain a signing certificate and test installation paths for a public Windows release. The supplied launcher is for local tests, not public hosting.

## Linux x86-64 dedicated server

```sh
godot --headless --export-release "Linux Server" build/server/howlguard-server.x86_64
```

Run with `--headless`. This dedicated-server preset sets the feature that starts the server. There is no display/GPU requirement for the simulation. Linux runtime execution and Docker deployment still need testing on the selected host.

## Android debug APK

This machine initially had no JDK, Android SDK or connected Android device; local APK/AAB exports are not claimed. The included CI debug job installs toolchains on GitHub's runner. To export locally:

1. Install OpenJDK **17** and the Android SDK. In Godot Editor Settings → Export → Android, set Java SDK Path and Android SDK Path.
2. Install platform-tools, build-tools 36.1.0, Android platform 36, NDK 29.0.14206865 and CMake 3.10.2.4988404. The SDK/build-tools/NDK values match the actual [Godot 4.7.2 Android template configuration](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/java/app/config.gradle). Follow the [official Android setup instructions](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html) for Java/path configuration. Check the pinned template when generic documentation still lists older SDK packages.
3. Create a debug keystore using Android Studio or `keytool`, configure it in Godot, install matching Godot export templates and install the Android build template from the Project menu. Both Android presets use Gradle. From the project root run `python tools/prepare-gradle.py`; it checks compile/target SDK 36 and selects AGP 8.9.1 while retaining the matching Gradle 8.11.1 wrapper. Android lists AGP 8.9.1 as the [minimum for API 36](https://developer.android.com/build/releases/about-agp). Godot 4.6's command-line exporter rejects a target above 35; use the pinned 4.7.2 engine, not just a patched old template.
4. Export `Android APK` with debug enabled (or the command below). INTERNET and ACCESS_NETWORK_STATE permissions are enabled. Landscape is fixed; touch maps to the common mouse input path. The build targets ARM64 devices, Android 8+.

```sh
godot --headless --export-debug "Android APK" build/android/howlguard-debug.apk
adb install -r build/android/howlguard-debug.apk
```

Enter the hosted WSS address on the phone. `127.0.0.1` means the phone itself. Debug keys are for sideload testing, not for store release.

## Signed Android App Bundle

1. Pick your final application ID before publishing; the preset's `com.howlguard.nightorchard` is a starting identifier, not a claim of registration. Increment version code for every Play upload.
2. Use Project → Install Android Build Template (called Setup Android Build in newer versions). The `Android AAB` preset enables Gradle and AAB output. Match the template to the editor.
3. Generate a private **upload keystore**, store it outside the repository, and back it up securely. Use one password for store and key with this export setup. Configure release path, alias and password through the editor or documented environment variables.
4. Export `Android AAB` as release, then validate it with current Android `bundletool`, APK/manifest analysis and Play's internal testing track.

```sh
godot --headless --export-release "Android AAB" build/android/howlguard-release.aab
```

For GitHub's manual `android-release.yml`, create an `android-release` environment and three secrets:

- `ANDROID_UPLOAD_KEY_BASE64`: base64 of the private upload keystore.
- `ANDROID_UPLOAD_KEY_ALIAS`: its signing alias.
- `ANDROID_UPLOAD_KEY_PASSWORD`: its password.

Environment protection/review is optional but recommended for the private key. Secrets never belong in `export_presets.cfg`, Git history or the source ZIP. The workflow supplies [Godot's documented release-key environment variables](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html), decodes the key only to runner temp, exports, then deletes it. It **does not upload to Google Play**.

The unrun workflow is prepared infrastructure, not evidence of a valid signed Play bundle. Android target API, native-library/page-size compatibility, signing, crash behavior and actual device performance must be checked before submission.
