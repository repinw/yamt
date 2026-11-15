import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_discard_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The back button, the tabs of the cooking (Töpfe · Kochen · Portion) and
/// the menu with "Verwerfen". Every tab up to [current] is filled.
class KochmodusStepBar extends StatelessWidget {
  /// Creates the bar.
  const new({
    required this.current,
    required this.locked,
    required this.onSelect,
    required this.onBack,
    required this.onDiscard,
    super.key,
  });

  /// Key of the tab of [step].
  static ValueKey<String> tabKey(KochmodusStep step) =>
      ValueKey<String>('kochmodus-tab-${step.name}');

  /// The tab shown.
  final KochmodusStep current;

  /// The tabs that cannot open yet; they show faded and do nothing.
  final Set<KochmodusStep> locked;

  /// Shows the tab.
  final ValueChanged<KochmodusStep> onSelect;

  /// Goes back to the Kochbuch.
  final VoidCallback onBack;

  /// Discards the run; `null` hides the menu.
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final onDiscard = this.onDiscard;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        onDiscard == null ? AppSpacing.xl : AppSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: materialL10n.backButtonTooltip,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          for (final step in KochmodusStep.values)
            Expanded(
              child: AppInkWell(
                key: tabKey(step),
                onTap: locked.contains(step) ? null : () => onSelect(step),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppGraphit.buttonHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppGraphit.progressSegmentGap,
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.xxs,
                      children: [
                        SizedBox(
                          height: AppGraphit.progressSegmentHeight,
                          width: double.infinity,
                          child: ColoredBox(
                            color: step.index <= current.index
                                ? colors.ink
                                : colors.track,
                          ),
                        ),
                        // Three tabs share a phone's width: with large text
                        // a name shrinks to fit instead of being cut off.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            _name(l10n, step),
                            maxLines: 1,
                            softWrap: false,
                            style: textTheme.labelSmall?.copyWith(
                              color: locked.contains(step)
                                  ? colors.muted.withValues(
                                      alpha: AppOpacities.disabledContent,
                                    )
                                  : step == current
                                  ? colors.ink
                                  : colors.muted,
                              fontWeight: step == current
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (onDiscard != null) KochmodusDiscardMenu(onDiscard: onDiscard),
        ],
      ),
    );
  }

  static String _name(AppLocalizations l10n, KochmodusStep step) =>
      switch (step) {
        KochmodusStep.pots => l10n.kochmodusStepPots,
        KochmodusStep.cook => l10n.cookStepCooking,
        KochmodusStep.portion => l10n.kochmodusStepPortion,
      };
}
