import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
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
      1 => HomeTabType.calories,
      2 => HomeTabType.settings,
      _ => HomeTabType.inventory, // coverage:ignore-line
    };
  }

  String _titleForTab(AppLocalizations l10n) {
    switch (_currentTab()) {
      case HomeTabType.inventory:
        return l10n.inventoryPageTitle;
      case HomeTabType.calories:
        return l10n.homeCalories;
      case HomeTabType.settings:
        return l10n.homeSettings;
    }
  }

  List<_HomeNavEntry> _navEntries(BuildContext context, AppLocalizations l10n) {
    final currentTab = _currentTab();

    return [
      _HomeNavEntry(
        item: _HomeNavItem(
          icon: Icons.inventory_2_rounded,
          label: l10n.homeInventory,
        ),
        isSelected: currentTab == HomeTabType.inventory,
        onTap: () => _onTabTapped(0),
      ),
      _HomeNavEntry(
        item: _HomeNavItem(
          icon: Icons.bar_chart_rounded,
          label: l10n.homeCalories,
        ),
        isSelected: currentTab == HomeTabType.calories,
        onTap: () => _onTabTapped(1),
      ),
      _HomeNavEntry(
        item: _HomeNavItem(
          icon: Icons.insights_rounded,
          label: l10n.homeStatistics,
        ),
        isSelected: false,
        onTap: () => _showSnackBar(context, l10n.commonNotImplementedYet),
      ),
      _HomeNavEntry(
        item: _HomeNavItem(
          icon: Icons.person_rounded,
          label: l10n.homeSettings,
        ),
        isSelected: currentTab == HomeTabType.settings,
        onTap: () => _onTabTapped(2),
      ),
    ];
  }

  List<Widget> _buildActions(BuildContext context, AppLocalizations l10n) {
    if (_currentTab() != HomeTabType.inventory) {
      return const <Widget>[];
    }

    return [
      IconButton(
        tooltip: l10n.commonNotImplementedYet,
        onPressed: () => _showSnackBar(context, l10n.commonNotImplementedYet),
        icon: const Icon(Icons.assignment_outlined),
      ),
      IconButton(
        tooltip: l10n.homeShopping,
        onPressed: () => context.push(AppRoutes.homeShopping),
        icon: const Icon(Icons.shopping_cart_rounded),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTab = _currentTab();

    return Scaffold(
      extendBody: true,
      appBar: _HomeTopBar(
        title: _titleForTab(l10n),
        titleColor: currentTab == HomeTabType.inventory
            ? AppInventoryEditorial.primary
            : null,
        actions: _buildActions(context, l10n),
      ),
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: HomeContextFab(currentTab: currentTab),
      bottomNavigationBar: _HomeBottomNavBar(
        entries: _navEntries(context, l10n),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeTopBar({
    required this.title,
    required this.actions,
    this.titleColor,
  });

  final String title;
  final List<Widget> actions;
  final Color? titleColor;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = AppInventoryEditorialSurfaces.ghostBorder(
      colors,
    ).withValues(alpha: 0.1);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppInventoryEditorial.glassBlur,
          sigmaY: AppInventoryEditorial.glassBlur,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.4),
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: preferredSize.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: titleColor ?? colors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBottomNavBar extends StatelessWidget {
  const _HomeBottomNavBar({required this.entries});

  final List<_HomeNavEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppInventoryEditorial.cardRadius);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              AppInventoryEditorialSurfaces.ambientBoxShadow(
                colors,
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppInventoryEditorial.glassBlur,
                sigmaY: AppInventoryEditorial.glassBlur,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow.withValues(alpha: 0.7),
                  borderRadius: radius,
                  border: Border.all(
                    color: AppInventoryEditorialSurfaces.ghostBorder(
                      colors,
                    ).withValues(alpha: 0.65),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      for (final entry in entries)
                        Expanded(
                          child: _HomeBottomNavItemButton(
                            item: entry.item,
                            isSelected: entry.isSelected,
                            onTap: entry.onTap,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBottomNavItemButton extends StatelessWidget {
  const _HomeBottomNavItemButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _HomeNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor = isSelected
        ? colors.primary
        : colors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: foregroundColor, size: 22),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNavItem {
  const _HomeNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _HomeNavEntry {
  const _HomeNavEntry({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _HomeNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
}
