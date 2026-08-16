import 'package:string_similarity/string_similarity.dart';
import 'package:faranka/database/database.dart';
import 'package:drift/drift.dart';

class CategoryEngine {
  final AppDatabase db;
  CategoryEngine(this.db);

  // --- 1. Normalization ---
  String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .trim();
  }

  // --- 2. The Matcher ---
  Future<String> findOrCreateCategory(String rawReason) async {
    if (rawReason.isEmpty) return "Uncategorized";

    final normalizedInput = normalize(rawReason);
    if (normalizedInput.isEmpty) {
      return "Uncategorized";
    }

    // Fetch all existing categories
    final existingCategories = await db.select(db.categories).get();

    String? bestMatch;
    double highestScore = 0.0;

    for (var cat in existingCategories) {
      // Compare normalized strings using package similarity API.
      double score = normalizedInput.similarityTo(cat.normalizedName);

      if (score > highestScore) {
        highestScore = score;
        bestMatch = cat.name;
      }
    }

    // --- 3. Threshold Check (70%) ---
    if (highestScore >= 0.70 && bestMatch != null) {
      return bestMatch;
    } else {
      // Create new category if no good match found
      final newCatName = _capitalize(normalizedInput);
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              name: newCatName,
              normalizedName: normalizedInput,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      return newCatName;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? "" : "${s[0].toUpperCase()}${s.substring(1)}";

}
