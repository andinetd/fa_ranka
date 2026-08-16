import 'package:shared_preferences/shared_preferences.dart';

const _prefix = 'tutorial_';
const _suffix = '_seen';
const _allPages = ['home', 'transactions', 'budgets', 'insights', 'settings'];

Future<bool> isTutorialSeen(String pageName) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('$_prefix$pageName$_suffix') ?? false;
}

Future<void> markTutorialSeen(String pageName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('$_prefix$pageName$_suffix', true);
}

Future<void> resetAllTutorials() async {
  final prefs = await SharedPreferences.getInstance();
  for (final page in _allPages) {
    await prefs.remove('$_prefix$page$_suffix');
  }
}
