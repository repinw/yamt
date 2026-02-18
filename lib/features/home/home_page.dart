import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  String _titleForTab(AppLocalizations l10n) {
    switch (navigationShell.currentIndex) {
      case 0:
        return l10n.homeInventory;
      case 1:
        return l10n.homeShopping;
      case 2:
        return l10n.homeCalories;
      case 3:
        return l10n.homeSettings;
      default:
        return l10n.homeTitle; // coverage:ignore-line
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(_titleForTab(l10n))),
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: HomeContextFab(
        currentTabIndex: navigationShell.currentIndex,
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
