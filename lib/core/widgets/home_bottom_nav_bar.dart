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
import 'package:yamt/core/widgets/home_nav_label_sizes.dart';

/// Bottom navigation bar used by the home shell pages.
///
/// The tabs sit in a floating capsule. Beside it stands the tab's [action]
/// as a lime button with a plus and the action's word under it, so the button
/// keeps its size for every word.
///
/// The four tab words share one size: the largest at which every word fits
/// its tab with [AppGraphit.navWordGap] on each side, never above the scaled
/// label size. The action word fits its button the same way and is never
/// larger than the tab words.
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
    return LayoutBuilder(
      builder: (context, constraints) => _build(
        context,
        homeNavLabelSizes(
          context,
          width:
              constraints.maxWidth - MediaQuery.paddingOf(context).horizontal,
          words: [for (final entry in entries) entry.item.label],
          actionWord: action.label,
        ),
      ),
    );
  }

  Widget _build(BuildContext context, HomeNavLabelSizes sizes) {
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
                  sizes: sizes,
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
                    _ActionButton(action: action, sizes: sizes),
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

class _ActionButton extends StatelessWidget {
  const new({required this.action, required this.sizes});

  final HomeNavAction action;
  final HomeNavLabelSizes sizes;

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
              padding: const EdgeInsets.symmetric(
                horizontal: AppGraphit.navWordGap,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.xxs,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: colors.onAccent,
                    size: AppSizes.homeBottomNavIcon,
                  ),
                  _NavWord(
                    label: action.label,
                    height: sizes.height,
                    style: homeNavLabelStyle(
                      context,
                      colors.onAccent,
                      weight: FontWeight.w700,
                      fontSize: sizes.action,
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
    required this.sizes,
    required this.isSelected,
    required this.onTap,
  });
  final HomeNavItem item;
  final HomeNavLabelSizes sizes;
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
                _NavWord(
                  label: item.label,
                  height: sizes.height,
                  style: homeNavLabelStyle(
                    context,
                    isSelected ? colors.ink : colors.muted,
                    weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: sizes.tab,
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

/// A word of the bar at its final size in a line of the reserved [height].
///
/// The height is the scaled line height, so it grows with large text like
/// any text container; the word itself may be smaller to fit its tab.
class _NavWord extends StatelessWidget {
  const new({required this.label, required this.height, required this.style});

  final String label;
  final double height;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          textScaler: TextScaler.noScaling,
          style: style,
        ),
      ),
    );
  }
}
