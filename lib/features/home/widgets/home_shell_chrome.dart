import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Tabs shown in the shared home shell.
enum HomeTabType { inventory, diary, settings }

/// Top app bar used by the home shell pages.
class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTopBar({
    super.key,
    required this.title,
    required this.actions,
    this.titleColor,
    this.titleIcon,
  });

  final String title;
  final List<Widget> actions;
  final Color? titleColor;
  final IconData? titleIcon;

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
                      child: Row(
                        children: [
                          if (titleIcon != null) ...[
                            Icon(
                              titleIcon,
                              color: titleColor ?? colors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
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
                        ],
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

/// Data needed to render one item in the home bottom navigation.
class HomeNavItem {
  const HomeNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// UI state and action for a single home navigation entry.
class HomeNavEntry {
  const HomeNavEntry({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final HomeNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
}

/// Bottom glass navigation bar used by the home shell pages.
class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({super.key, required this.entries});

  final List<HomeNavEntry> entries;

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

  final HomeNavItem item;
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
