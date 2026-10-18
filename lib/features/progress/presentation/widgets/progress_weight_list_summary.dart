import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_chart.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Head of the weight list: the change since the start of the range, the
/// trend, the way left to the goal weight, the pace, and the chart with the
/// goal weight.
class ProgressWeightListSummary extends StatelessWidget {
  /// Creates the summary of [list].
  const new({required this.list, super.key});

  /// The weighings and the trend.
  final ProgressWeightList list;

  /// Stable key of the summary.
  static const summaryKey = ValueKey<String>('progress-weights-summary');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final kg = NumberFormat('0.0', locale);
    final signedKg = NumberFormat('+0.0;−0.0', locale);
    final today = list.trend.days.last.day;
    final start =
        (list.start.year == today.year
                ? DateFormat.MMMd(locale)
                : DateFormat.yMMMd(locale))
            .format(list.start);
    final trend = list.trend;
    final trendKg = trend.trendWeightKg;
    final change = list.changeKg;
    final toTarget = list.kgToTarget;
    final perWeek = trend.trendKgPerWeek;
    return Column(
      key: summaryKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressSectionHeader(
          kicker: list.startsAtGoal
              ? l10n.progressWeightsSinceGoal(start)
              : l10n.progressWeightsSince(start),
          value: change == null ? l10n.profileNoValue : signedKg.format(change),
          unit: l10n.caloriesUnitKg,
          lines: [
            if (trendKg != null) l10n.progressWeightsTrend(kg.format(trendKg)),
            if (toTarget != null)
              l10n.progressWeightsToTarget(kg.format(toTarget)),
            if (perWeek != null)
              l10n.progressWeightPerWeek(signedKg.format(perWeek)),
          ],
        ),
        // Without a trend the page shows its own empty note below.
        if (trendKg != null) ...[
          const SizedBox(height: AppSpacing.md),
          ProgressWeightChart(
            trend: trend,
            goalStarts: list.goalStarts,
            targetWeightKg: list.targetWeightKg,
            ignored: list.ignoredWeighings,
          ),
        ],
      ],
    );
  }
}
