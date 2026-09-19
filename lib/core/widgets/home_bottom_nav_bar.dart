import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/home_nav_entry.dart';
import 'package:yamt/core/widgets/home_nav_item.dart';

/// Bottom navigation bar used by the home shell pages.
class HomeBottomNavBar extends StatelessWidget {
  /// The home bottom nav bar.
  const new({required this.entries, super.key});

  /// The entries.
  final List<HomeNavEntry> entries;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(
              alpha: AppOpacities.homeBottomNavBorder,
            ),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              for (final entry in entries)
                Expanded(
                  child: _HomeBottomNavItemButton(
                    item: entry.item,
                    isSelected: entry.isSelected,
                    showTopIndicator: entry.showTopIndicator,
                    onTap: entry.onTap,
                  ),
                ),
            ],
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
    required this.showTopIndicator,
  });
  final HomeNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showTopIndicator;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor = isSelected
        ? colors.primary
        : colors.onSurfaceVariant.withValues(
            alpha: AppOpacities.homeBottomNavUnselected,
          );
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppDurations.homeBottomNavIndicator,
                curve: Curves.easeOutCubic,
                width: showTopIndicator
                    ? AppSizes.homeBottomNavIndicatorWidth
                    : 0,
                height: AppSizes.homeBottomNavIndicatorHeight,
                decoration: BoxDecoration(
                  color: showTopIndicator ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Icon(
                item.icon,
                color: foregroundColor,
                size: AppSizes.homeBottomNavIcon,
              ),
              const SizedBox(height: AppSpacing.xxs),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foregroundColor,
                      fontSize: AppFontSizes.homeBottomNavLabel,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
