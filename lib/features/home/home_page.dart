import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/home/home_tab_page.dart';
import 'package:yamt/features/home/widgets/home_context_fab.dart';
import 'package:yamt/l10n/app_localizations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  HomeTabType _currentTab() {
    return switch (navigationShell.currentIndex) {
      0 => HomeTabType.inventory,
      1 => HomeTabType.shopping,
      2 => HomeTabType.calories,
      3 => HomeTabType.settings,
      _ => HomeTabType.inventory, // coverage:ignore-line
    };
  }

  String _titleForTab(AppLocalizations l10n) {
    switch (_currentTab()) {
      case HomeTabType.inventory:
        return l10n.homeInventory;
      case HomeTabType.shopping:
        return l10n.homeShopping;
      case HomeTabType.calories:
        return l10n.homeCalories;
      case HomeTabType.settings:
        return l10n.homeSettings;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(_titleForTab(l10n))),
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: HomeContextFab(currentTab: _currentTab()),
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
