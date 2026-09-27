import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/activity/presentation/diary_weight_tracking_flow.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_formatters.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_kicker.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_weight_chart.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The trend weight as the main number, the chart of the last days, the last
/// weigh-in, the start weight, the weekly trend, and a button to weigh in.
class ProfileWeightCard extends ConsumerWidget {
  /// Creates the weight card for [state].
  const new({required this.state, super.key});

  /// The profile summary to show.
  final ProfileSummaryState state;

  /// Stable key of the weigh-in button.
  static const addWeightButtonKey = ValueKey<String>('profile-add-weight');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = FoodLabelColors.of(context);
    final format = ProfileFormatters.of(context);
    final today = normalizeLocalDay(ref.watch(clockProvider)());
    final weight = state.weight;
    final trendKg = weight?.trendWeightKg;

    return Container(
      padding: AppInsets.card,
      color: label.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileKicker(text: l10n.tdeeWeightStatTrend),
                    Text(
                      trendKg == null
                          ? l10n.profileNoValue
                          : l10n.settingsProfileSummaryWeightValue(
                              format.decimal(trendKg),
                            ),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: label.accentText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.profileWeightChartDays(RecentWeightTrend.chartDayCount),
                style: theme.textTheme.bodySmall?.copyWith(color: label.muted),
              ),
            ],
          ),
          if (weight != null) ProfileWeightChart(days: weight.days),
          Divider(height: AppSizes.hairline, color: label.rule),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _measuredFact(context, today)),
              Expanded(
                child: _WeightFact(
                  label: l10n.profileWeightStartLabel,
                  value: _kg(context, state.profile?.weightKg),
                  note: l10n.profileWeightStartNote,
                ),
              ),
              Expanded(
                child: _WeightFact(
                  label: l10n.profileWeightTrendLabel,
                  value: switch (weight?.trendKgPerWeek) {
                    final perWeek? => l10n.settingsProfileSummaryWeightValue(
                      format.signedDecimal(perWeek),
                    ),
                    null => l10n.profileNoValue,
                  },
                  note: l10n.profileWeightPerWeek,
                ),
              ),
            ],
          ),
          FilledButton.tonalIcon(
            key: addWeightButtonKey,
            onPressed: () => unawaited(
              ref
                  .read(diaryWeightTrackingFlowProvider)
                  .showDialogForDay(
                    context: context,
                    selectedDay: today,
                    day: today,
                    initialWeightKg: weight?.latestWeighInKg,
                  ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: label.tile,
              foregroundColor: label.ink,
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.diaryWeightAddAction),
          ),
        ],
      ),
    );
  }

  Widget _measuredFact(BuildContext context, DateTime today) {
    final l10n = AppLocalizations.of(context)!;
    final day = state.weight?.latestWeighInDay;
    return _WeightFact(
      label: l10n.profileWeightMeasuredLabel,
      value: _kg(context, state.weight?.latestWeighInKg),
      note: day == null
          ? null
          : l10n.profileWeighInDay(
              today.difference(normalizeLocalDay(day)).inDays,
            ),
    );
  }

  String _kg(BuildContext context, double? weightKg) {
    final l10n = AppLocalizations.of(context)!;
    if (weightKg == null) {
      return l10n.profileNoValue;
    }
    return l10n.settingsProfileSummaryWeightValue(
      ProfileFormatters.of(context).decimal(weightKg),
    );
  }
}

class _WeightFact extends StatelessWidget {
  const new({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = FoodLabelColors.of(context).muted;
    final note = this.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (note != null)
          Text(note, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
      ],
    );
  }
}
