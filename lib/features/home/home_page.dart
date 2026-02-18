import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> _debugSignOut(WidgetRef ref) async {
    await ref.read(firebaseAuthProvider).signOut();
  }

  void _onQuickActionPressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Quick action tapped')));
  }

  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: 'Debug logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _debugSignOut(ref),
          ),
        ],
      ),
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _onQuickActionPressed(context),
        tooltip: 'Quick action',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_outlined),
            label: l10n.homeInventory,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart_outlined),
            label: l10n.homeShopping,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_fire_department_outlined),
            label: l10n.homeCalories,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.homeSettings,
          ),
        ],
      ),
    );
  }
}
