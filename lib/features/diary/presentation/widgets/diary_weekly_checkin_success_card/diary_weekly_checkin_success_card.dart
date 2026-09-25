import 'dart:async' show unawaited;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Message that the weekly check-in set a new goal, in a thin frame with a
/// close button.
class DiaryWeeklyCheckInSuccessCard extends StatelessWidget {
  /// The diary weekly check-in success card.
  const new({required this.goalKcal, required this.onDismiss, super.key});

  /// Goal kcal.
  final double goalKcal;

  /// Called when the user closes the message.
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final colors = FoodLabelColors.of(context);

    return DecoratedBox(
      key: DiaryWeeklyCheckInCardKeys.successCard,
      decoration: BoxDecoration(
        border: Border.all(color: colors.rule, width: AppFoodLabel.chipOutline),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.caloriesWeeklyCheckInAutoAdjustedHint} '
                '${numberFormat.format(goalKcal.round())} '
                '${l10n.caloriesUnitKcal}.',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontFamily: AppFonts.mono, color: colors.ink),
              ),
            ),
            IconButton(
              key: DiaryWeeklyCheckInCardKeys.successCardClose,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => unawaited(onDismiss()),
              icon: Icon(Icons.close_rounded, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
