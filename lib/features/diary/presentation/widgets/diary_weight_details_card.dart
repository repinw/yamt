part of 'diary_activity_weight_cards.dart';

Future<bool> _deleteWeight({
  required _DiaryWeightActions weightActions,
  required DateTime selectedDay,
  required DiaryWeightDayData weightDay,
}) {
  return weightActions.deleteWeight(
    selectedDay: selectedDay,
    day: weightDay.day,
    hasManualWeight: weightDay.hasManualWeight,
    healthSample: weightDay.healthSample,
  );
}

Future<void> _showWeightDialog({
  required BuildContext context,
  required _DiaryWeightActions weightActions,
  required DateTime selectedDay,
  required DateTime day,
  required double? initialWeightKg,
  required bool hasManualWeight,
  required bool canClearWeight,
  required HealthWeightSample? healthSample,
}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final dayLabel = DateFormat.yMMMd(locale).format(day);

  return showCalorieHealthWeightDialog(
    context: context,
    dayLabel: dayLabel,
    initialWeightKg: initialWeightKg,
    hasManualWeight: canClearWeight,
    onSaveWeight: (weightKg) async {
      return weightActions.saveManualWeight(
        selectedDay: selectedDay,
        day: day,
        weightKg: weightKg,
      );
    },
    onClearWeight: () async {
      return weightActions.deleteWeight(
        selectedDay: selectedDay,
        day: day,
        hasManualWeight: hasManualWeight,
        healthSample: healthSample,
      );
    },
  );
}

class _WeightDetailsCard extends ConsumerWidget {
  const _WeightDetailsCard({required this.data, required this.selectedDay});

  final DiaryActivityWeightData data;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
    final days = data.weightDays.reversed.toList(growable: false);
    final selectedWeightDay = data.weightDays.where((weightDay) {
      return isSameDiaryDay(weightDay.day, normalizedSelectedDay);
    }).firstOrNull;
    final weightActions = ref.read(_diaryWeightActionsProvider);

    return DiaryDetailCardShell(
      child: _WeightDetailsContent(
        days: days,
        onAdd: () => unawaited(
          _showWeightDialog(
            context: context,
            weightActions: weightActions,
            selectedDay: normalizedSelectedDay,
            day: normalizedSelectedDay,
            initialWeightKg: data.selectedWeightKg,
            hasManualWeight: selectedWeightDay?.hasManualWeight ?? false,
            canClearWeight: selectedWeightDay?.canDeleteWeight ?? false,
            healthSample: selectedWeightDay?.healthSample,
          ),
        ),
        onEdit: (weightDay) => unawaited(
          _showWeightDialog(
            context: context,
            weightActions: weightActions,
            selectedDay: normalizedSelectedDay,
            day: weightDay.day,
            initialWeightKg: weightDay.weightKg,
            hasManualWeight: weightDay.hasManualWeight,
            canClearWeight: weightDay.canDeleteWeight,
            healthSample: weightDay.healthSample,
          ),
        ),
        onDelete: (weightDay) => unawaited(
          _deleteWeight(
            weightActions: weightActions,
            selectedDay: normalizedSelectedDay,
            weightDay: weightDay,
          ),
        ),
      ),
    );
  }
}

class _WeightDetailsContent extends StatelessWidget {
  const _WeightDetailsContent({
    required this.days,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<DiaryWeightDayData> days;
  final VoidCallback onAdd;
  final ValueChanged<DiaryWeightDayData> onEdit;
  final ValueChanged<DiaryWeightDayData> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.MMMEd(locale);
    final accentColors = DiaryAccentColors.of(context);
    final weightFormat = NumberFormat('0.#', locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_down_rounded,
              color: accentColors.weight,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.diaryWeightTitle.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _WeightAddRow(onPressed: onAdd),
        const SizedBox(height: AppSpacing.sm),
        Divider(color: colors.outlineVariant, height: 1),
        const SizedBox(height: AppSpacing.sm),
        if (days.isEmpty)
          Text(
            l10n.diaryWeightEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          for (final day in days) ...[
            _WeightHistoryRow(
              day: day,
              dayLabel: dateFormat.format(day.day),
              weightLabel: day.weightKg == null
                  ? '—'
                  : '${weightFormat.format(day.weightKg)} '
                        '${l10n.caloriesUnitKg}',
              onEdit: () => onEdit(day),
              onDelete: day.canDeleteWeight ? () => onDelete(day) : null,
            ),
            if (day != days.last) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(color: colors.outlineVariant, height: 1),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
      ],
    );
  }
}

class _WeightAddRow extends StatelessWidget {
  const _WeightAddRow({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final accentColors = DiaryAccentColors.of(context);

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(14),
      child: AppInkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentColors.weight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: accentColors.weight,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.diaryWeightAddAction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightHistoryRow extends StatelessWidget {
  const _WeightHistoryRow({
    required this.day,
    required this.dayLabel,
    required this.weightLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final DiaryWeightDayData day;
  final String dayLabel;
  final String weightLabel;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accentColors = DiaryAccentColors.of(context);
    final hasWeight = day.weightKg != null;

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(14),
      child: AppInkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                weightLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: hasWeight ? colors.onSurface : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                icon: Icon(
                  hasWeight ? Icons.edit_rounded : Icons.add_rounded,
                  color: accentColors.weight,
                  size: 16,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.error,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
