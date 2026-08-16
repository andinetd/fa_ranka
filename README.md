# Faranka

Faranka is an open-source Flutter app for parsing bank SMS messages, extracting transaction data, and presenting spending insights in a clean dashboard.

## Highlights

- Imports Awash and CBE SMS messages.
- Parses transaction details, receipts, and related links.
- Stores messages locally with Drift.
- Groups transactions by category and time.
- Supports Android background catch-up for incoming SMS.

## Repository Structure

- `lib/app` app bootstrap, routing, and theme.
- `lib/features` feature modules for UI, domain, and data.
- `lib/infrastructure` shared services, background work, and device/network integrations.
- `lib/database` Drift schema and generated code.
- `docs` architecture notes and contributor-facing documentation.
- `test` widget and integration-style checks.

## Getting Started

### Requirements

- Flutter SDK 3.8+
- Android Studio or Android SDK for mobile builds
- A device or emulator with SMS permissions for live imports

### Run Locally

```bash
flutter pub get
flutter run
```

### Validate

```bash
flutter analyze
flutter test
```

## Development Workflow

1. Open or create an issue using the templates in `.github/ISSUE_TEMPLATE`.
2. Make the smallest useful change in the relevant feature or infrastructure layer.
3. Run `flutter analyze` and `flutter test` before opening a pull request.
4. Use the pull request template in `.github/pull_request_template.md` and include screenshots for UI changes.

## Privacy and Safety

The app requests SMS and network permissions because it processes financial messages and can fetch receipt content when available. Keep test data, logs, and screenshots free of private account details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for coding standards, review expectations, and collaboration guidelines.

## Additional Docs

See [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md) for how releases and updates work, and [docs/EXTRACTION_RETRY_GUIDE.md](docs/EXTRACTION_RETRY_GUIDE.md) for import retry behavior.

## License

See [LICENSE](LICENSE).

## Release & Updates

Releases are distributed through the **app store** — users get updates by updating Faranka from the store, just like any other Android app. Build the release artifact with:

```bash
flutter build appbundle --release
```

For sideload testing (pre-store), build a signed APK and share it directly:

```bash
flutter build apk --release
```

Notes about install conflicts:

- Android will refuse to install an APK whose package (`applicationId`) matches an installed app but whose signing certificate differs. To avoid the "package conflicts with an existing package" error, ensure the release APK is signed with the same key as the currently installed app, or uninstall the existing app first.
- The `applicationId` used by this app is defined in `android/app/build.gradle.kts` (look for `applicationId = "com.genzeb.faranka"`).
