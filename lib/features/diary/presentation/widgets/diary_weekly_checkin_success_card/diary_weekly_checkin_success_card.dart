import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines diary weekly check-in success card.
class DiaryWeeklyCheckInSuccessCard extends StatelessWidget {
  /// The diary weekly check-in success card.
  const DiaryWeeklyCheckInSuccessCard({required this.goalKcal, super.key});

  /// Goal kcal.
  final double goalKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: DiaryWeeklyCheckInCardKeys.successCard,
      decoration: AppQuietSurfaces.cardDecoration(colors),
      child: Padding(
        padding: AppInsets.card,
        child: Text(
          '${l10n.caloriesWeeklyCheckInAutoAdjustedHint} '
          '${numberFormat.format(goalKcal.round())} ${l10n.caloriesUnitKcal}.',
        ),
      ),
    );
  }
}
