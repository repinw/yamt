import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';

const _compactHomeChromeTextScaleThreshold = 1.15;
const _compactBottomNavItemWidth = 88.0;

double _effectiveTextScale(
  BuildContext context, {
  double referenceFontSize = 14,
}) {
  return MediaQuery.textScalerOf(
        context,
      ).scale(referenceFontSize) /
      referenceFontSize;
}

/// Whether shared home chrome should switch to its compact layout.
bool shouldUseCompactHomeChrome(BuildContext context) {
  return isCompactViewport(context) ||
      _effectiveTextScale(context) > _compactHomeChromeTextScaleThreshold;
}

/// Tabs shown in the shared home shell.
enum HomeTabType {
  /// Inventory.
  inventory,

  /// Diary.
  diary,

  /// Statistics.
  statistics,

  /// Settings.
  settings,
}

/// Top app bar used by the home shell pages.
class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// The home top bar.
  const HomeTopBar({
    required this.title,
    required this.actions,
    super.key,
    this.compact = false,
    this.titleColor,
    this.titleIcon,
  });

  /// The title.
  final String title;

  /// The actions.
  final List<Widget> actions;

  /// Whether to use compact spacing for tight layouts.
  final bool compact;

  /// The title color.
  final Color? titleColor;

  /// The title icon.
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
            color: AppInventoryEditorialSurfaces.glass(colors),
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: preferredSize.height,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
                ),
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
                            child: MediaQuery.withClampedTextScaling(
                              maxScaleFactor: 1.15,
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: titleColor ?? colors.onSurface,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty)
                      SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
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
  /// The home nav item.
  const HomeNavItem({required this.icon, required this.label});

  /// The icon.
  final IconData icon;

  /// The label.
  final String label;
}

/// UI state and action for a single home navigation entry.
class HomeNavEntry {
  /// The home nav entry.
  const HomeNavEntry({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  /// The item.
  final HomeNavItem item;

  /// Whether selected.
  final bool isSelected;

  /// The on tap.
  final VoidCallback onTap;
}

/// Bottom glass navigation bar used by the home shell pages.
class HomeBottomNavBar extends StatelessWidget {
  /// The home bottom nav bar.
  const HomeBottomNavBar({required this.entries, super.key});

  /// The entries.
  final List<HomeNavEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compactChrome = shouldUseCompactHomeChrome(context);
    final radius = BorderRadius.circular(AppInventoryEditorial.cardRadius);
    final horizontalInset = compactChrome ? AppSpacing.lg : AppSpacing.xl;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          0,
          horizontalInset,
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final navHorizontalPadding = compactChrome
                        ? AppSpacing.xs
                        : AppSpacing.sm;
                    final showLabels =
                        !compactChrome &&
                        (constraints.maxWidth - (navHorizontalPadding * 2)) /
                                entries.length >=
                            _compactBottomNavItemWidth;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        navHorizontalPadding,
                        compactChrome ? AppSpacing.xs : AppSpacing.sm,
                        navHorizontalPadding,
                        compactChrome ? AppSpacing.sm : AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          for (final entry in entries)
                            Expanded(
                              child: _HomeBottomNavItemButton(
                                item: entry.item,
                                isSelected: entry.isSelected,
                                onTap: entry.onTap,
                                showLabel: showLabels,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
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
    required this.showLabel,
  });

  final HomeNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor = isSelected
        ? colors.primary
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? AppSpacing.xs : AppSpacing.xxs,
            vertical: showLabel ? AppSpacing.sm : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                color: foregroundColor,
                size: showLabel ? 22 : 24,
              ),
              if (showLabel) ...[
                const SizedBox(height: AppSpacing.xs),
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.0,
                  child: Text(
                    item.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foregroundColor,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
