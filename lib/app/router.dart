import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell_scaffold.dart';
import 'package:faranka/features/auth/presentation/pages/unlock_page.dart';
import 'package:faranka/features/home/presentation/pages/home_page.dart';
import 'package:faranka/features/receipts/presentation/pages/results_page.dart';
import 'package:faranka/features/receipts/presentation/pages/setup_page.dart';
import 'package:faranka/features/transactions/presentation/pages/receipt_details_page.dart';
import 'package:faranka/features/categories/presentation/pages/category_debug_page.dart';
import 'package:faranka/features/transactions/presentation/pages/all_transactions_page.dart';
import 'package:faranka/features/budgets/presentation/pages/budgets_screen.dart';
import 'package:faranka/features/budgets/presentation/pages/budget_detail_page.dart';
import 'package:faranka/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:faranka/features/goals/presentation/pages/create_goal_page.dart';
import 'package:faranka/features/budgets/presentation/pages/create_budget_page.dart';
import 'package:faranka/features/insights/presentation/pages/insights_screen.dart';
import 'package:faranka/features/settings/presentation/pages/settings_page.dart';
import 'package:faranka/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:faranka/features/settings/presentation/pages/help_faq_page.dart';
import 'package:faranka/database/database.dart';
import 'package:faranka/app/core/providers/is_first_run_provider.dart';
import 'package:faranka/features/auth/presentation/providers/biometric_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

String? _redirect(BuildContext context, GoRouterState state) {
  final location = state.matchedLocation;
  final isUnlockRoute = location == '/unlock';

  if (!isFirstRun && biometricEnabled && !biometricPassed) {
    if (!isUnlockRoute) return '/unlock';
    return null;
  }

  if (isUnlockRoute && (!biometricEnabled || biometricPassed)) {
    return '/';
  }

  return null;
}

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: isFirstRun ? '/setup' : '/',
  redirect: _redirect,
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ShellScaffold(child: child);
      },
      routes: [
        GoRoute(
          name: 'home',
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          name: 'transactions',
          path: '/transactions',
          builder: (context, state) {
            DateTime? startDate;
            DateTime? endDate;

            final startParam = state.uri.queryParameters['start'];
            final endParam = state.uri.queryParameters['end'];

            if (startParam != null) {
              startDate = DateTime.tryParse(startParam);
            }
            if (endParam != null) {
              endDate = DateTime.tryParse(endParam);
            }

            return AllTransactionsPage(startDate: startDate, endDate: endDate);
          },
        ),
        GoRoute(
          path: '/budgets',
          builder: (context, state) => const BudgetsScreen(),
        ),
        GoRoute(
          path: '/insights',
          builder: (context, state) => const InsightsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
    GoRoute(path: '/setup', builder: (context, state) => const SetupPage()),
    GoRoute(
      name: 'create-budget',
      path: '/create-budget',
      builder: (context, state) => CreateBudgetPage(
        categoryNames: state.extra is List<String>
            ? state.extra as List<String>
            : ['General'],
      ),
    ),
    GoRoute(
      name: 'create-goal',
      path: '/create-goal',
      builder: (context, state) => const CreateGoalPage(),
    ),
    GoRoute(
      name: 'budget-detail',
      path: '/budgets/:id',
      builder: (context, state) {
        final budgetId = int.tryParse(state.pathParameters['id'] ?? '');
        if (budgetId == null) {
          return const Scaffold(body: Center(child: Text('Invalid budget')));
        }
        return BudgetDetailPage(budgetId: budgetId);
      },
    ),
    GoRoute(
      name: 'goal-detail',
      path: '/goals/:id',
      builder: (context, state) {
        final goalId = int.tryParse(state.pathParameters['id'] ?? '');
        if (goalId == null) {
          return const Scaffold(body: Center(child: Text('Invalid goal')));
        }
        return GoalDetailPage(goalId: goalId);
      },
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) {
        final extra = state.extra;
        final Map<String, int> data;
        if (extra is Map<String, int>) {
          data = extra;
        } else if (extra is Map) {
          data = <String, int>{
            for (final entry in extra.entries)
              if (entry.value is num)
                entry.key.toString(): (entry.value as num).toInt(),
          };
        } else {
          data = const {};
        }
        return ResultsPage(messageData: data);
      },
    ),
    GoRoute(
      path: '/receipt-details',
      builder: (context, state) {
        final extra = state.extra;
        SmsInboxData? sms;
        if (extra is SmsInboxData) {
          sms = extra;
        } else if (extra is Map<String, dynamic>) {
          sms = SmsInboxData.fromJson(extra);
        }
        if (sms == null) {
          return const Scaffold(body: Center(child: Text('No SMS data')));
        }
        return ReceiptDetailsPage(sms: sms);
      },
    ),
    GoRoute(
      path: '/category/:name',
      builder: (context, state) {
        final category = Uri.decodeComponent(
          state.pathParameters['name'] ?? 'Unknown',
        );
        final directionStr = state.uri.queryParameters['direction'];
        final direction = directionStr != null
            ? TransactionDirection.values[int.tryParse(directionStr) ?? 0]
            : null;
        return AllTransactionsPage(
          startDate: null,
          endDate: null,
          initialCategory: category,
          initialDirection: direction,
        );
      },
    ),

    GoRoute(
      path: '/debug/categories',
      builder: (context, state) => const CategoriesPage(),
    ),
    GoRoute(path: '/unlock', builder: (context, state) => const UnlockPage()),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    GoRoute(
      path: '/help-faq',
      builder: (context, state) => const HelpFaqPage(),
    ),
  ],
);
