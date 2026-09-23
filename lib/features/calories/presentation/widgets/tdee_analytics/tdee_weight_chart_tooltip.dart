import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart_builder.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Touch tooltips for the weight chart.
abstract final class TdeeWeightChartTooltip {
  /// Builds touch tooltips with the day, trend weight, and scale weight.
  static LineTouchData build(
    ColorScheme colorScheme,
    ThemeData theme, {
    required DateTime firstDay,
    required String locale,
    required AppLocalizations l10n,
  }) {
    final dateFormat = DateFormat.MMMEd(locale);
    final weightFormat = NumberFormat('0.0', locale);
    final style = theme.textTheme.labelMedium!.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    );
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (touchedSpots) => [
          for (final (index, spot) in touchedSpots.indexed)
            LineTooltipItem(
              [
                if (index == 0)
                  dateFormat.format(addDiaryDays(firstDay, spot.x.round())),
                _tooltipValue(spot.barIndex, weightFormat.format(spot.y), l10n),
              ].join('\n'),
              style,
            ),
        ],
      ),
    );
  }

  static String _tooltipValue(
    int barIndex,
    String weight,
    AppLocalizations l10n,
  ) {
    return switch (barIndex) {
      TdeeWeightChartBuilder.trendBarIndex => l10n.tdeeWeightTrendValue(weight),
      TdeeWeightChartBuilder.scaleBarIndex => l10n.tdeeWeightScaleValue(weight),
      _ => '$weight ${l10n.caloriesUnitKg}',
    };
  }
}
