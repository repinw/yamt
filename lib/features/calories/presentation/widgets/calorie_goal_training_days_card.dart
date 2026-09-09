import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Card to configure training days and calorie cycling offset.
class CalorieGoalTrainingDaysCard extends StatelessWidget {
  /// Creates the training days configuration card.
  const CalorieGoalTrainingDaysCard({
    required this.baseGoalKcal,
    required this.trainingWeekdays,
    required this.trainingDayKcalOffset,
    required this.onTrainingWeekdaysChanged,
    required this.onOffsetChanged,
    super.key,
  });

  /// Base daily calorie target.
  final double baseGoalKcal;

  /// Selected weekdays (1 = Monday, 7 = Sunday).
  final List<int> trainingWeekdays;

  /// Calorie offset for training days.
  final double trainingDayKcalOffset;

  /// Callback when weekdays change.
  final ValueChanged<List<int>> onTrainingWeekdaysChanged;

  /// Callback when offset changes.
  final ValueChanged<double> onOffsetChanged;

  static const _weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const _offsetOptions = [0.0, 150.0, 200.0, 250.0, 300.0];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final trainingCount = trainingWeekdays.length;
    final restCount = 7 - trainingCount;
    final hasCycling =
        trainingDayKcalOffset > 0 && trainingCount > 0 && restCount > 0;
    final restOffset = hasCycling
        ? (trainingCount * trainingDayKcalOffset) / restCount
        : 0.0;
    final trainingGoal = (baseGoalKcal + trainingDayKcalOffset).round();
    final restGoal = (baseGoalKcal - restOffset).round().clamp(1200, 10000);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Trainingstage & Calorie Cycling',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Mehr Kalorien an Trainingstagen, weniger an Ruhetagen '
              'bei gleichem Wochenbudget.',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Trainingstage wählen',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                final isSelected = trainingWeekdays.contains(weekday);
                return AppInkWell(
                  onTap: () {
                    final next = List<int>.from(trainingWeekdays);
                    if (isSelected) {
                      next.remove(weekday);
                    } else {
                      next
                        ..add(weekday)
                        ..sort();
                    }
                    onTrainingWeekdaysChanged(next);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary
                          : colors.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      _weekdayLabels[index],
                      style: TextStyle(
                        color: isSelected ? colors.onPrimary : colors.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Zusatz-Kalorien pro Trainingstag',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: _offsetOptions.map((offset) {
                final isSelected = trainingDayKcalOffset == offset;
                return ChoiceChip(
                  label: Text(
                    offset == 0
                        ? 'Gleichmäßig (0 kcal)'
                        : '+${offset.toInt()} kcal',
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onOffsetChanged(offset),
                );
              }).toList(),
            ),
            if (hasCycling) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    _TrainingDayResultRow(
                      label: '🏋️ Training ($trainingCount Tage)',
                      value: '$trainingGoal kcal',
                    ),
                    const SizedBox(height: 4),
                    _TrainingDayResultRow(
                      label: '🛋️ Ruhetag ($restCount Tage)',
                      value: '$restGoal kcal',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainingDayResultRow extends StatelessWidget {
  const _TrainingDayResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
