# Release Process

This document describes how a new version of the Faranka (Genzeb) Android app is
released end to end: bumping the version, building a release artifact, signing,
and distributing it. The app is distributed exclusively through the **app store**
(Google Play); there is no in-app update mechanism. Release builds and KS and
verification notes are documented here so the process stays repeatable.

---

## 1. Overview

`pubspec.yaml` is the **single source of truth** for the version:

```yaml
version: 1.1.11+88
#          ^name  ^code
```

- **Version name** (`1.1.11`) — the human-readable release shown to users ("Version 1.1.11").
- **Version code** (`88`) — the monotonically increasing integer the app store uses
  to determine upgrade ordering. It must **strictly increase** between store uploads.

## 2. Versioning rules

1. **Bump `version` in `pubspec.yaml` before every release.**
2. **`version_code` must only ever increase.** Never re-upload the same or a lower
   code to the store.

## 3. Building a release

### Prerequisites

- A signing keystore configured via `android/app/key.properties` (this file is
  gitignored). See [`docs/ANDROID_SIGNING_RUNBOOK.md`](ANDROID_SIGNING_RUNBOOK.md).

### Steps

1. **Bump the version** in `pubspec.yaml`:
   ```yaml
   version: 1.1.12+89
   ```

2. **Run checks locally**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   flutter analyze
   flutter test
   ```

3. **Build the artifact** against the app store or sideload:
   ```bash
   flutter build appbundle --release        # store upload (AAB)
   flutter build apk --release              # sideload APK
   ```

4. **Sign** the artifact if `android/app/key.properties` is not configured to sign
   automatically (store-password and key settings in `android/app/build.gradle.kts`).

## 4. Distribution

- **Google Play:** upload the generated `.aab` via the Play Console, then promote
  from the internal/closed track to production as appropriate.
- **Sideload tests:** share the release-signed APK directly (e.g. a test cohort).
  Users must uninstall an existing install if the signing certificate differs.

Users receive updates through the ordinary store update flow. There is no OTA
endpoint, no `update.json`, and no in-app update logic in the application.

## 5. Verification checklist

After a release, confirm:

- [ ] `flutter analyze` is clean.
- [ ] `flutter test` passes in full.
- [ ] `app/build.gradle.kts` `applicationId` == `com.genzeb.faranka`.
- [ ] `version_code` strictly increased.
- [ ] App launches on an emulator/device, notifications initialize (no
      `invalid_icon` error), widgets update.

## 6. Troubleshooting

| Symptom | Cause / Fix |
| ------- | ----------- |
| `SigningConfig "release" is missing required property "storeFile"` | `key.properties` was not written. Check the keystore secret and that the keystore file exists. |
| Build killed with `exit code 143` around the ~14 min mark | Gradle daemon memory too high for the runner. Keep `android/gradle.properties` at CI-safe values (`-Xmx3072m`, `kotlin.daemon.jvmargs=-Xmx1536m`, `org.gradle.workers.max=2`). |
| `Notification init failed ... resource @drawable/ic_notification could not be found` | The resource shrinker stripped `ic_notification` (referenced only by string in `notification_service.dart`). Kept by `android/app/src/main/res/raw/keep.xml` with `tools:keep="@drawable/ic_notification"`. Don't delete that file. |

### Known constraints

- Do **not** commit a keystore password in `android/app/key.properties` — that
  file is gitignored.
- `flutter build apk` works on the local machine; invoking `./gradlew` directly
  may fail — always build through the Flutter tool.