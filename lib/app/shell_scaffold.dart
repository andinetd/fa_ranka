import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/widgets/home_bottom_nav.dart';
import '../../features/receipts/presentation/widgets/import_progress_mini_card.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const ImportProgressMiniCard(),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: _calculateSelectedIndex(context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == '/') {
      return 0;
    }
    if (location.startsWith('/transactions')) {
      return 1;
    }
    if (location.startsWith('/budgets')) {
      return 2;
    }
    if (location.startsWith('/insights')) {
      return 3;
    }
    if (location.startsWith('/settings')) {
      return 4;
    }
    return 0;
  }
}
