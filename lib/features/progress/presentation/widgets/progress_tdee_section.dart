import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/progress/application/progress_tdee_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_tdee.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_axis_labels.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_legend.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_tdee_chart.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The TDEE per confirmed weekly check-in of the goals of a scope.
class ProgressTdeeSection extends ConsumerWidget {
  /// Creates the TDEE section for [scope].
  const new({required this.scope, super.key});

  /// Which goals the chart covers.
  final ProgressScope scope;

  /// Stable key of the section.
  static const sectionKey = ValueKey<String>('progress-tdee-section');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(progressTdeeProvider(scope))
        .when(
          data: (tdee) => _TdeeContent(key: sectionKey, tdee: tdee),
          loading: () => const ProgressSectionLoading(),
          error: (_, _) => const ProgressSectionError(),
        );
  }
}

class _TdeeContent extends StatelessWidget {
  const new({required this.tdee, super.key});

  final ProgressTdee tdee;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final signed = NumberFormat('+#,##0;−#,##0', locale);
    final date = DateFormat.MMMd(locale);
    final current = tdee.currentTdeeKcal;
    final change = tdee.lastChangeKcal;
    final checkIns = tdee.checkIns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressSectionHeader(
          kicker: l10n.progressTdeeKicker,
          value: current == null ? '–' : number.format(current.round()),
          unit: l10n.caloriesUnitKcal,
          lines: [
            if (change != null)
              l10n.progressTdeeChange(signed.format(change.round())),
            if (tdee.isCheckInOpen)
              l10n.progressTdeeCheckInOpen
            else
              l10n.progressTdeeNextCheckIn(date.format(tdee.nextCheckInDay)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (current == null)
          ProgressSectionNote(text: l10n.progressTdeeEmpty)
        else ...[
          ProgressTdeeChart(tdee: tdee, goalLabel: l10n.progressGoalMarker),
          const SizedBox(height: AppSpacing.xxs),
          ProgressAxisLabels(
            labels: [
              switch (tdee.goals.firstOrNull?.startDay) {
                final start? => date.format(start),
                null => l10n.progressTdeeLegendStart,
              },
              if (checkIns.isNotEmpty) date.format(checkIns.last.day),
              date.format(tdee.nextCheckInDay),
            ],
          ),
          if (checkIns.isEmpty)
            ProgressSectionNote(text: l10n.progressTdeeEmpty),
          const SizedBox(height: AppSpacing.sm),
          ProgressLegend(
            items: [
              if (checkIns.isNotEmpty)
                ProgressLegendItem.color(
                  colors.ink,
                  l10n.progressTdeeLegendTaken,
                ),
              if (checkIns.any((checkIn) => checkIn.isRejected))
                ProgressLegendItem(
                  swatch: _HollowSwatch(color: colors.muted),
                  label: l10n.progressTdeeLegendKept,
                ),
              if (tdee.goals.any((goal) => goal.startTdeeKcal != null))
                ProgressLegendItem(
                  swatch: _HollowSwatch(color: colors.muted),
                  label: l10n.progressTdeeLegendStart,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HollowSwatch extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppProgress.legendSwatch,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: AppProgress.baseStroke),
        ),
      ),
    );
  }
}
