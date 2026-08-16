# Android Signing Runbook (Single Source of Truth)

This runbook defines one canonical signing path so release APKs stay consistent and installable over time.

## 1) Policy

- Use exactly one canonical release keystore for all release APK builds.
- CI builds are the source of release artifacts.
- Debug builds are never used as release candidates.
- The keystore and `key.properties` must never be committed to the repository.

## 2) Canonical Values

- Android package name: `com.genzeb.faranka`
- Canonical release keystore: `android/app/release_keystore.jks`

Keep these values in sync with:
- `android/app/key.properties` (local, gitignored)
- GitHub secrets used by the release workflow

## 3) One-Time Setup (Local)

Generate (or confirm) the release keystore and read its fingerprints.

```bash
keytool -list -v -keystore android/app/release_keystore.jks -alias <ALIAS> -storepass <STORE_PASS> -keypass <KEY_PASS>
```

## 4) GitHub Secrets (Required)

Set these repository secrets (used by the release workflow):

- `RELEASE_KEYSTORE`: base64 of canonical keystore file
- `KEYSTORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`
- `EXPECTED_RELEASE_SHA1`: canonical SHA-1 (lowercase, no colons recommended)

Generate base64 for `RELEASE_KEYSTORE`:

```bash
base64 -w0 android/app/release_keystore.jks
```

## 5) SL guardrails (Expected Behavior)

The release workflow should fail early when:

- `RELEASE_KEYSTORE` is missing.
- `EXPECTED_RELEASE_SHA1` is missing.
- Decoded keystore SHA-1 != `EXPECTED_RELEASE_SHA1`.
- Built APK signing SHA-1 != `EXPECTED_RELEASE_SHA1`.

This guarantees no drift between the configured keystore and the built artifact.

## 6) Release Checklist

1. Confirm local canonical keystore SHA-1.
2. Confirm GitHub secrets are set from the same keystore.
3. Trigger the release workflow.
4. Confirm workflow logs show:
   - decoded keystore SHA-1 equals expected SHA-1
   - APK cert SHA-1 equals expected SHA-1
5. Publish only the CI-produced APK/AAB.

## 7) Team Rule to Prevent Recurrence

- Never rotate the release keystore silently.
- Any keystore rotation requires:
  - an explicit migration PR
  - `EXPECTED_RELEASE_SHA1` update
  - a release dry run in CI before publishing.