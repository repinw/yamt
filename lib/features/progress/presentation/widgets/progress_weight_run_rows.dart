import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// [day] as a short weekday and date, with the year when it is not
/// [currentYear].
String progressWeightDay(DateTime day, int currentYear, String locale) {
  return day.year == currentYear
      ? DateFormat.MEd(locale).format(day)
      : DateFormat.yMEd(locale).format(day);
}

/// Head of a 7-day run: its number and first day, the trend weight at its
/// end, and the change against the run before.
class ProgressWeightRunHeader extends StatelessWidget {
  /// Creates the head of [run], dated against [currentYear].
  const new({required this.run, required this.currentYear, super.key});

  /// The run.
  final ProgressWeightRun run;

  /// The year of today; other years show in the date.
  final int currentYear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final day = progressWeightDay(run.start, currentYear, locale);
    final kg = NumberFormat('0.0', locale);
    final signedKg = NumberFormat('+0.0;−0.0', locale);
    final trend = run.trendWeightKg;
    final change = run.changeKg;
    final style = progressKickerStyle(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          Expanded(
            child: Text(
              switch (run.number) {
                final number? => l10n.progressWeightsRun(number, day),
                null => l10n.progressWeightsSince(day),
              }.toUpperCase(),
              style: style,
            ),
          ),
          if (trend != null)
            Flexible(
              child: Text(
                change == null
                    ? l10n.progressWeightsTrend(kg.format(trend))
                    : l10n.progressWeightsRunTrend(
                        kg.format(trend),
                        signedKg.format(change),
                      ),
                textAlign: TextAlign.end,
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

/// One weighing: day, time, weight, and where it comes from.
class ProgressWeighingRow extends StatelessWidget {
  /// Creates the row of [weighing], dated against [currentYear].
  const new({required this.weighing, required this.currentYear, super.key});

  /// The weighing.
  final ProgressWeighing weighing;

  /// The year of today; other years show in the date.
  final int currentYear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final textTheme = Theme.of(context).textTheme;
    final muted = FoodLabelColors.of(context).muted;
    final at = weighing.at;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          Expanded(
            child: Text(
              progressWeightDay(weighing.day, currentYear, locale),
              style: textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              at == null
                  ? l10n.profileNoValue
                  : DateFormat.Hm(locale).format(at),
              style: textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          Expanded(
            child: Text(
              l10n.settingsProfileSummaryWeightValue(
                NumberFormat('0.0', locale).format(weighing.weightKg),
              ),
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              switch (weighing.source) {
                ProgressWeighingSource.manual =>
                  l10n.progressWeightsSourceManual,
                ProgressWeighingSource.scale => l10n.progressWeightsSourceScale,
              },
              textAlign: TextAlign.end,
              style: textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
