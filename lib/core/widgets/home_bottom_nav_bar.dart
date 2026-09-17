import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/home_nav_entry.dart';
import 'package:yamt/core/widgets/home_nav_item.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';

const _bottomNavLabelMinItemWidth = 64.0;
const _bottomNavTopIndicatorWidth = 20.0;

/// Bottom navigation bar used by the home shell pages.
class HomeBottomNavBar extends StatelessWidget {
  /// The home bottom nav bar.
  const new({required this.entries, super.key});

  /// The entries.
  final List<HomeNavEntry> entries;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compactChrome = shouldUseCompactHomeChrome(context);
    final radius = BorderRadius.circular(AppRadius.xl);
    final horizontalInset = compactChrome ? AppSpacing.xxs : AppSpacing.xs;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          0,
          horizontalInset,
          AppSpacing.xl,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: radius,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const navHorizontalPadding = AppSpacing.xs;
                final availablePerItem = entries.isEmpty
                    ? 0.0
                    : (constraints.maxWidth - (navHorizontalPadding * 2)) /
                          entries.length;
                final showLabels =
                    availablePerItem >= _bottomNavLabelMinItemWidth;
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
                            showTopIndicator: entry.showTopIndicator,
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
    );
  }
}

class _HomeBottomNavItemButton extends StatelessWidget {
  const new({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.showLabel,
    required this.showTopIndicator,
  });
  final HomeNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showLabel;
  final bool showTopIndicator;
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
      child: AppInkWell(
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: showTopIndicator ? _bottomNavTopIndicatorWidth : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: showTopIndicator ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              SizedBox(height: showTopIndicator ? AppSpacing.xs : 0),
              Icon(
                item.icon,
                color: foregroundColor,
                size: showLabel ? 22 : 24,
              ),
              if (showLabel) ...[
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foregroundColor,
                        fontSize: AppFontSizes.homeBottomNavLabel,
                        letterSpacing: 1,
                      ),
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
