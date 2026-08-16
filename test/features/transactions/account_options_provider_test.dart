import 'package:flutter_test/flutter_test.dart';

import 'package:faranka/features/transactions/presentation/providers/transaction_data_providers.dart';

void main() {
  group('buildAccountOptions', () {
    test('always starts with All Accounts even with no banks', () {
      expect(buildAccountOptions(null), ['All Accounts']);
      expect(buildAccountOptions(const []), ['All Accounts']);
    });

    test('lists distinct banks after the All Accounts sentinel', () {
      expect(
        buildAccountOptions(['CBE', 'Awash Bank']),
        ['All Accounts', 'CBE', 'Awash Bank'],
      );
    });

    test('trims whitespace and drops blank values', () {
      final result = buildAccountOptions(['  CBE  ', '   ', '', 'Awash Bank']);
      expect(result, ['All Accounts', 'CBE', 'Awash Bank']);
    });

    test('dedupes repeated banks', () {
      final result = buildAccountOptions(['Telebirr', 'telebirr', 'Telebirr']);
      expect(result, ['All Accounts', 'Telebirr', 'telebirr']);
    });

    test('handles many banks without collapsing', () {
      final result = buildAccountOptions(const [
        'Awash Bank',
        'CBE',
        'Telebirr',
        'BoA',
        'Abyssinia',
        'Dashen',
        'Bank of Oromia',
        'Amhara',
        'Zemen',
        'CBO',
        'NBE',
      ]);
      expect(result.first, 'All Accounts');
      expect(result.length, 12);
      expect(result.toSet().length, result.length);
    });
  });

  group('bankFilterOptions', () {
    test('starts with All Banks and drops the All Accounts sentinel', () {
      expect(
        bankFilterOptions(const ['All Accounts', 'CBE', 'Awash Bank'], 'All Banks'),
        ['All Banks', 'CBE', 'Awash Bank'],
      );
    });

    test('returns just All Banks when there are no banks', () {
      expect(bankFilterOptions(const ['All Accounts'], 'All Banks'), ['All Banks']);
    });

    test('falls back to All Banks when loading state has only the sentinel', () {
      final result = bankFilterOptions(const ['All Accounts'], 'Telebirr');
      expect(result, ['All Banks', 'Telebirr']);
    });

    test('appends the current selection when missing from the fresh list', () {
      final accountOptions = buildAccountOptions(['CBE']); // ['All Accounts', 'CBE']
      expect(
        bankFilterOptions(accountOptions, 'BoA'),
        ['All Banks', 'CBE', 'BoA'],
      );
    });

    test('keeps selection unchanged when the bank is available', () {
      final accountOptions = buildAccountOptions(['Telebirr']);
      expect(
        bankFilterOptions(accountOptions, 'Telebirr'),
        ['All Banks', 'Telebirr'],
      );
    });
  });
}