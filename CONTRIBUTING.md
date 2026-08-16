# Contributing to Faranka

Thanks for taking the time to contribute.

## Before You Start

- Fork the repository or create a branch from `main`.
- Install dependencies with `flutter pub get`.
- Make sure `flutter analyze` and `flutter test` pass before opening a pull request.

## Project Structure

- `lib/app` contains routing, app bootstrap, and theme.
- `lib/features` contains feature-specific UI, domain, and data code.
- `lib/infrastructure` contains shared services, background work, and device integrations.
- `lib/database` contains the Drift schema and generated database code.

## Adding Support for a New Bank

Use the existing Awash and CBE implementations as the reference pattern.

1. Add a new parser in `lib/features/receipts/data/parsers/`.
2. Keep the parser focused on SMS normalization and field extraction such as amount, direction, counterparty, date, time, transaction ID, balance, and receipt URL.
3. Preserve `Unknown` when direction cannot be determined. Do not guess `Credit` or `Debit` unless the SMS clearly says so.
4. Add a matching receipt service in `lib/features/receipts/data/services/` if the bank exposes receipt pages, PDFs, or HTML detail pages.
5. Update `lib/features/transactions/domain/usecases/transaction_processor.dart` so the new sender is routed to the new parser and follow-up service.
6. If the bank needs background ingestion, make sure the background worker path still saves raw SMS first and can retry later from local storage.
7. Add tests for representative SMS samples, including edge cases such as missing URLs, missing transaction IDs, and ambiguous direction text.
8. Update user-facing copy or documentation if the new bank introduces new permissions, new import steps, or special limitations.

## Code Style

- Keep changes small and focused.
- Prefer feature-local code over new shared abstractions unless the logic is truly reused.
- Follow the existing Flutter lint rules and formatting.
- Avoid adding new dependencies unless they solve a concrete problem.

## Workflow

1. Create a branch for your change.
2. Make the smallest useful implementation.
3. Run `flutter analyze` and `flutter test`.
4. Update or add tests when behavior changes.
5. Open a pull request with a clear description and screenshots when relevant.

## Commit Messages

Use short, descriptive commit messages. A good format is:

Use the Conventional Commits style: `type(scope): subject`.

Examples:

- `feat(receipts): add category export`
- `fix(import): handle offline receipt sync`
- `docs(readme): improve setup guide`

## Pull Request Checklist

- The app builds locally.
- Tests pass.
- The analyzer passes.
- The change has no private data or credentials.
- The PR description explains what changed and why.
