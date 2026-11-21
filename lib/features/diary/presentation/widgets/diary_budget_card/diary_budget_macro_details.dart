import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Eaten of target grams of [macro], and its counted plans; the eaten grams
/// alone on a pause day.
class DiaryBudgetMacroDetails extends StatelessWidget {
  /// Creates the details of [macro].
  const new({
    required this.macro,
    required this.isPauseDay,
    required this.numberFormat,
    super.key,
  });

  /// The macro.
  final DiaryBudgetMacro macro;

  /// Whether the day is a pause day.
  final bool isPauseDay;

  /// Locale number format.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamily: AppFonts.geist, color: colors.muted);
    String grams(num value) => numberFormat.format(value.round());

    return Text.rich(
      key: DiaryBudgetCardKeys.macroTotal(macro.kind),
      TextSpan(
        text: isPauseDay
            ? l10n.diaryBudgetMacroEaten(grams(macro.eaten))
            : l10n.diaryMacroEatenOfTarget(
                grams(macro.eaten + macro.planned),
                grams(macro.target),
              ),
        children: [
          if (macro.planned.round() > 0)
            TextSpan(
              text: '\n${l10n.diaryBudgetMacroPlanned(grams(macro.planned))}',
              style: style?.copyWith(color: colors.plan),
            ),
        ],
      ),
      style: style,
    );
  }
}
