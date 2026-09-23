import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Trend weight, its change over the range, and its weekly rate.
class TdeeWeightStatsRow extends StatelessWidget {
  /// Creates the weight stats row.
  const new({required this.summary, super.key});

  /// Summary that holds the trend weight numbers.
  final TdeeAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final currentWeight = summary.currentWeightKg;
    if (currentWeight == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final unit = l10n.caloriesUnitKg;
    final weightFormat = NumberFormat('0.0', locale);
    final deltaFormat = NumberFormat('+0.0;-0.0', locale);
    final rateFormat = NumberFormat('+0.00;-0.00', locale);
    final change = summary.weightChangeKg;
    final rate = summary.weeklyRateKg;

    return Row(
      children: [
        Expanded(
          child: _TdeeWeightStat(
            label: l10n.tdeeWeightStatTrend,
            value: '${weightFormat.format(currentWeight)} $unit',
          ),
        ),
        Expanded(
          child: _TdeeWeightStat(
            label: l10n.tdeeChangeLabel,
            value: change == null ? '–' : '${deltaFormat.format(change)} $unit',
          ),
        ),
        Expanded(
          child: _TdeeWeightStat(
            label: l10n.tdeeWeightStatRate,
            value: rate == null ? '–' : '${rateFormat.format(rate)} $unit',
          ),
        ),
      ],
    );
  }
}

class _TdeeWeightStat extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
