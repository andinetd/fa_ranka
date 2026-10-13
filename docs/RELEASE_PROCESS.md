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
- **Version code** (`88`) — the monotonically increasing integer used to determine upgrade ordering. It must **strictly increase** with each release.

## 2. Release & In-App Update Architecture

Faranka uses an automated release pipeline combined with client-side update checking:

1. **Triggering a Release**:
   - Committing and pushing code to the repository **does not** trigger a release build or update.
   - Releases are triggered by **publishing a GitHub Release** with a tag matching `v<version_name>` (e.g., `v1.1.12`).
   - The workflow (`.github/workflows/build-release.yml`):
     - Validates that `version_code` in `pubspec.yaml` is strictly greater than the one currently published on `andinetd/genze-eb-web/main/update.json`.
     - Builds the split-per-abi release APK (`app-arm64-v8a-release.apk`).
     - **Repo 1 (`andinetd/fa_ranka`)**: Uploads the release APK artifacts directly to the GitHub Release of the primary repository.
     - **Repo 2 (`andinetd/genze-eb-web`)**: Copies the APK to `andinetd/genze-eb-web/public/faranka.apk` and updates `update.json` with the new version code, version name, release notes, and timestamp.
2. **In-App Update Detection**:
   - The app periodically checks `https://raw.githubusercontent.com/andinetd/genze-eb-web/main/update.json` via `AppUpdateService`.
   - On startup, a silent background check runs (rate-limited to at most once every 12 hours).
   - If an update is detected (`remote.version_code > local.version_code`), an "UPDATE" badge appears on the App Version tile in **Settings**.
   - Users can tap the App Version tile in Settings at any time to manually check for updates.
   - When an update is available, tapping the update prompt or manual check opens a dialog with the release notes and a direct button to download the APK via browser/external app.

## 3. Versioning rules

1. **Bump `version` in `pubspec.yaml` before publishing a release.**
2. **`version_code` must only ever increase.** The CI pipeline rejects builds where `version_code` is less than or equal to the published version.

## 4. Releasing a New Version

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

3. **Commit and push** to the branch (e.g., `main`).

4. **Publish a GitHub Release**:
   - Go to GitHub -> Releases -> Draft a new release.
   - Set tag to `v1.1.12` (must match `v<version_name>`).
   - Publish the release.
   - GitHub Actions will build the release APK, upload it to the `genze-eb-web` repo, and update `update.json`.

5. **Client Update Availability**:
   - Within minutes of workflow completion, installed apps running version 88 or earlier will detect the update via `update.json`.

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