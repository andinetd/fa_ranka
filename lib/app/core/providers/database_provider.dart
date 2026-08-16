import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:faranka/database/database.dart';

AppDatabase? _database;

/// Must be called once before [database] or [databaseProvider] is accessed.
void initDatabase(AppDatabase db) {
  _database = db;
}

/// Direct access to the shared database singleton (for non-widget classes).
AppDatabase get database {
  assert(_database != null, 'initDatabase() must be called first');
  return _database!;
}

final databaseProvider = Provider<AppDatabase>((ref) {
  assert(_database != null, 'initDatabase() must be called first');
  return _database!;
});
