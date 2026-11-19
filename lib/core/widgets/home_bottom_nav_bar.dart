import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/home_nav_action.dart';
import 'package:yamt/core/widgets/home_nav_entry.dart';
import 'package:yamt/core/widgets/home_nav_item.dart';

/// Bottom navigation bar used by the home shell pages.
///
/// The tabs sit in a floating capsule. Beside it stands the tab's [action]
/// as a lime button with a plus and the action's word under it, so the button
/// keeps its size for every word.
class HomeBottomNavBar extends StatelessWidget {
  /// The home bottom nav bar.
  const new({required this.entries, required this.action, super.key});

  /// Key of the action button.
  static const actionKey = ValueKey<String>('home-nav-action');

  /// The entries.
  final List<HomeNavEntry> entries;

  /// The action of the current tab.
  final HomeNavAction action;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final capsule = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.rule, width: AppFoodLabel.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppGraphit.navCapsulePadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
    );
    // The fade is only to look at: taps in it reach the page.
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [colors.paper, colors.paper.withValues(alpha: 0)],
                  stops: const [0.5, 1],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppGraphit.navBarFade,
              AppSpacing.lg,
              AppGraphit.navBarBottomMargin,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppGraphit.navBarHeight,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.xs,
                  children: [
                    Expanded(child: capsule),
                    _ActionButton(action: action),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

TextStyle? _navLabelStyle(
  BuildContext context,
  Color color, {
  required FontWeight weight,
}) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    color: color,
    fontSize: AppFontSizes.homeBottomNavLabel,
    fontWeight: weight,
  );
}

class _ActionButton extends StatelessWidget {
  const new({required this.action});

  final HomeNavAction action;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: SizedBox(
        width: AppGraphit.navActionWidth,
        child: Material(
          color: colors.accent,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: AppInkWell(
            key: HomeBottomNavBar.actionKey,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () {
              AppHapticFeedback.mediumImpact();
              action.onPressed();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.xxs,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: colors.onAccent,
                    size: AppSizes.homeBottomNavIcon,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      action.label,
                      maxLines: 1,
                      style: _navLabelStyle(
                        context,
                        colors.onAccent,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
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
  });
  final HomeNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final radius = BorderRadius.circular(AppGraphit.navTabRadius);
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: AnimatedContainer(
        duration: AppDurations.homeBottomNavIndicator,
        decoration: BoxDecoration(
          color: isSelected ? colors.track : Colors.transparent,
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: AppInkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpacing.xxs,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? colors.accentText : colors.muted,
                  size: AppSizes.homeBottomNavIcon,
                ),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: _navLabelStyle(
                        context,
                        isSelected ? colors.ink : colors.muted,
                        weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
