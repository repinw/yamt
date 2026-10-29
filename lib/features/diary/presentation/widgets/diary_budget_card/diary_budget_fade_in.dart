import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';

/// Fades [child] in and slides it down a little when it first shows, as the
/// details of the budget card do when they open. Off when the system asks
/// for less motion.
class DiaryBudgetFadeIn extends StatelessWidget {
  /// Creates the fade.
  const new({required this.child, this.order = 0, super.key});

  /// The part that fades in.
  final Widget child;

  /// Place of [child] from top to bottom; each later place starts a little
  /// later.
  final int order;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = AppBudgetCard.fadeInStagger * order;
    final total = AppBudgetCard.fadeIn + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, shown, child) => Opacity(
        opacity: shown,
        child: Transform.translate(
          offset: Offset(0, (shown - 1) * AppBudgetCard.fadeInOffset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Cross-fades to the new [child] whenever [value] changes, as the card's
/// numbers and words do when "Nach Plan" or the view switch flips them. Off
/// when the system asks for less motion.
class DiaryBudgetCrossFade extends StatelessWidget {
  /// Creates the cross-fade.
  const new({
    required this.value,
    required this.child,
    this.alignment = AlignmentDirectional.topStart,
    super.key,
  });

  /// What [child] shows; a new value fades the old child out.
  final Object value;

  /// The part that fades.
  final Widget child;

  /// Where the old and the new child sit while both show.
  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppBudgetCard.fadeIn,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(value), child: child),
    );
  }
}
