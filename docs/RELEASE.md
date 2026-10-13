# Release and Google Play checklist

As of **13 October 2026**, nothing has been submitted or published to Google Play. There is no purchased developer account, configured signing identity, paid host or final privacy-policy URL created by this project.

## Developer setup

Create/verify your own Google Play developer account. Google lists a **US$25 one-time registration fee** and identity/account checks; new personal accounts also require Android-device verification. Review the [official account setup](https://support.google.com/googleplay/android-developer/answer/6112435).

Personal accounts created after 13 November 2023 must run a closed test with **at least 12 testers continuously opted in for 14 days**, then apply for production access. Testing alone does not automatically grant approval. Check the [current official testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465).

For new phone apps/app updates submitted after 31 August 2026, Google currently requires **Android 16 / API 36 or higher**. Both presets specify target 36; verify the exported manifest and Play Console acceptance, since a preset alone cannot establish compliance. See [official target SDK policy](https://developer.android.com/google/play/requirements/target-sdk).

## Before internal/closed testing

- Host a reliable WSS server with a trusted certificate, choose the default production endpoint, and validate Windows plus two actual phones on different networks.
- Set the final application ID, version code, support contact, developer identity and store branding. Check name availability; this original working name has not undergone a trademark search.
- Generate/back up the upload key and enroll in Play App Signing. Build a release AAB, not the debug APK.
- Verify 64-bit ARM libraries, Android 16 KB page-size compatibility, target/min SDK, manifest permissions and signing using the current Android tools. Run Play's pre-launch report; do not assume engine version alone proves compliance.
- Provide a published privacy policy, complete Data Safety, content rating, target audience, app-access instructions and other Play declarations accurately. Supply reviewer instructions for creating/joining a multiplayer room and testing with two users.
- Include phone screenshots from real gameplay, a store icon and feature graphic that meet current specifications. The included preview is a development fixture, not a phone screenshot or finished store listing.
- Test crashes/ANRs, low-memory devices, battery use, background/foreground, airplane mode, packet loss, high latency, notch/navigation-area layout, keyboard visibility, accessibility and different screen aspect ratios.
- Review violence/content rating for the stylized zombies. No ads, in-app purchases or child-directed design are implemented; make declarations consistent with the actual release and audience you select.
- Collect feedback on difficulty, shared spending, dog ownership and four-player cooperation. The bot's winning strategy is not user testing.

## Data handling to disclose accurately

Clients save the selected endpoint, display name, room code and secret reconnect token in their OS application storage. Servers temporarily hold player names, tokens and game state in memory; network infrastructure inherently sees IP addresses. This MVP has no account system, chat, advertising, analytics, payments or persistent match database. Hosting-provider logs, backups, monitoring and future SDKs may change disclosures. Choose retention behavior and a contact address for the actual deployment before writing the final policy.

## Windows

Distribute an extracted ZIP with the executable, console launcher, engine notices and server instructions, or create an installer later. Test on clean Windows 10/11 computers and select minimum hardware. Authenticode signing and a polished installer are not included. A Windows executable being built is not a store publication.

## Submission

Upload the signed bundle to an internal track, test, then complete the applicable closed-test/production-access steps and submit for review. Google decides review/approval; there is no guaranteed timeline. Make the app public only after hosting, testing and declarations are ready. The build workflows contain no store-upload credentials or auto-publish steps.
