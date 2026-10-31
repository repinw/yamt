import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_day_type_buttons.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_view_switch.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_preview_tap.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Sample grams of the preview: protein is over its target, fat has the
/// lowest share and takes its color.
typedef _Macro = ({
  String label,
  double eaten,
  double target,
  AppCustomColor key,
  Color color,
});

/// The budget card of the preview: the view switch and day type buttons of
/// a training day, kcal left after the plan, and the three macros as the
/// diary card shows them.
class SettingsCustomPreviewBudget extends StatelessWidget {
  /// Creates the card.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colors = FoodLabelColors.of(context);
    final metrics = MetricAccentColors.of(context);
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final macros = <_Macro>[
      (
        label: l10n.caloriesProteinLabel,
        eaten: 164,
        target: 160,
        key: AppCustomColor.protein,
        color: metrics.protein,
      ),
      (
        label: l10n.diaryBudgetCarbsLabel,
        eaten: 199,
        target: 260,
        key: AppCustomColor.carbs,
        color: metrics.carbs,
      ),
      (
        label: l10n.caloriesFatLabel,
        eaten: 41,
        target: 70,
        key: AppCustomColor.fat,
        color: metrics.fat,
      ),
    ];

    return SettingsCustomPreviewTap(
      color: AppCustomColor.card,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        // As on the diary card: the pause button's tap area reaches into
        // the end padding.
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppBudgetCard.padding,
            AppBudgetCard.topPadding,
            AppBudgetCard.padding - AppBudgetCard.dayTypeHitOverhang,
            AppBudgetCard.padding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppBudgetCard.sectionGap,
            children: [
              // The buttons only show; a tap picks the color they wear.
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      // Shrinks with large text, so the row never overflows.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SettingsCustomPreviewTap(
                          color: AppCustomColor.paper,
                          child: IgnorePointer(
                            child: DiaryBudgetViewSwitch(
                              showEaten: false,
                              onSelect: (_) {},
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SettingsCustomPreviewTap(
                    color: AppCustomColor.ink,
                    child: IgnorePointer(
                      child: DiaryBudgetDayTypeButtons(
                        selected: DiaryDayType.training,
                        onSelect: (_) {},
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: AppBudgetCard.dayTypeHitOverhang,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppBudgetCard.columnGap,
                  children: [
                    Expanded(
                      flex: AppBudgetCard.kcalColumnFlex,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.xxs,
                        children: [
                          // The kcal left take the accent, as on the card.
                          SettingsCustomPreviewTap(
                            color: AppCustomColor.accent,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                number.format(742),
                                maxLines: 1,
                                style: textTheme.displayLarge?.copyWith(
                                  fontFamily: AppFonts.geist,
                                  fontSize: AppBudgetCard.bigNumber,
                                  fontWeight: FontWeight.w800,
                                  height: AppBudgetCard.bigNumberLineHeight,
                                  letterSpacing:
                                      AppBudgetCard.bigNumber *
                                      AppBudgetCard.bigNumberTracking,
                                  color: colors.accentText,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SettingsCustomPreviewTap(
                            color: AppCustomColor.muted,
                            child: Text(
                              l10n.diaryBudgetKcalLeftAfterPlan,
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: AppFonts.geist,
                                fontWeight: FontWeight.w500,
                                color: colors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SettingsCustomPreviewTap(
                            color: AppCustomColor.accent,
                            child: DiaryBudgetLine(
                              eaten: 1180,
                              planned: 340,
                              target: 2262,
                              eatenColor: colors.accent,
                              // The planned part picks the plan color.
                              wrapPlanArea: (area) => SettingsCustomPreviewTap(
                                color: AppCustomColor.plan,
                                child: area,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: AppBudgetCard.macroColumnFlex,
                      child: Column(
                        spacing: AppSpacing.xs,
                        children: [
                          for (final (index, macro) in macros.indexed)
                            _MacroRow(
                              macro: macro,
                              isColored:
                                  metrics.allMacrosColored ||
                                  index == macros.length - 1,
                              number: number,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const new({
    required this.macro,
    required this.isColored,
    required this.number,
  });

  final _Macro macro;
  final bool isColored;
  final NumberFormat number;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colors = FoodLabelColors.of(context);
    final left = (macro.target - macro.eaten).round();
    final value = left < 0
        ? l10n.diaryBudgetMacroOver(number.format(-left))
        : l10n.diaryBudgetMacroLeft(number.format(left));

    return SettingsCustomPreviewTap(
      color: macro.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  macro.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: isColored ? macro.color : colors.muted,
                  ),
                ),
              ),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  fontFamily: AppFonts.geist,
                  // An overage keeps its text in ink, as on the diary card.
                  color: isColored && left >= 0 ? macro.color : colors.ink,
                ),
              ),
            ],
          ),
          DiaryBudgetLine(
            eaten: macro.eaten,
            target: macro.target,
            compact: true,
            eatenColor: isColored ? macro.color : null,
          ),
        ],
      ),
    );
  }
}
