import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/home_nav_action.dart';
import 'package:yamt/core/widgets/home_nav_entry.dart';
import 'package:yamt/core/widgets/home_nav_item.dart';

/// Bottom navigation bar used by the home shell pages.
///
/// With an [action], a round lime button sits in the middle of the bar and
/// reaches above its top edge; its word stands under it in the bar.
class HomeBottomNavBar extends StatelessWidget {
  /// The home bottom nav bar.
  const new({required this.entries, this.action, super.key});

  /// Key of the round action button.
  static const actionKey = ValueKey<String>('home-nav-action');

  /// The entries.
  final List<HomeNavEntry> entries;

  /// The action of the current tab, or `null` when the tab has none.
  final HomeNavAction? action;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final action = this.action;
    final middle = (entries.length / 2).ceil();
    final items = [
      for (final entry in entries)
        Expanded(
          child: _HomeBottomNavItemButton(
            item: entry.item,
            isSelected: entry.isSelected,
            onTap: entry.onTap,
          ),
        ),
    ];
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(
          top: BorderSide(color: colors.ink, width: AppFoodLabel.outline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ...items.take(middle),
              if (action != null)
                Expanded(child: _ActionLabel(label: action.label)),
              ...items.skip(middle),
            ],
          ),
        ),
      ),
    );
    if (action == null) {
      return bar;
    }
    // The transparent strip above the bar lets taps through to the page;
    // only the button takes them.
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppGraphit.navActionOverhang),
          child: bar,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: _ActionButton(action: action)),
        ),
      ],
    );
  }
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
      child: SizedBox.square(
        dimension: AppGraphit.navActionButton,
        child: FloatingActionButton(
          key: HomeBottomNavBar.actionKey,
          heroTag: null,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          onPressed: () {
            AppHapticFeedback.mediumImpact();
            action.onPressed();
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          style: _navLabelStyle(context, colors.ink),
        ),
      ),
    );
  }
}

TextStyle? _navLabelStyle(BuildContext context, Color color) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    fontFamily: AppFonts.mono,
    color: color,
    fontSize: AppFontSizes.homeBottomNavLabel,
    letterSpacing: AppFoodLabel.navLabelTracking,
  );
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
    final foregroundColor = isSelected ? colors.accentText : colors.muted;
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lime rule on top of the selected tab.
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: AppDurations.homeBottomNavIndicator,
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.homeBottomNavIndicatorHeight,
                child: ColoredBox(color: colors.accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        item.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _navLabelStyle(context, foregroundColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
