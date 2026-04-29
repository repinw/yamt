part of 'diary_activity_weight_cards.dart';

Future<bool> _deleteWeight({
  required WidgetRef ref,
  required DateTime selectedDay,
  required DiaryWeightDayData weightDay,
}) async {
  final deleted = weightDay.hasManualWeight
      ? await ref
            .read(manualHealthWeightEntriesControllerProvider.notifier)
            .deleteEntryForDay(weightDay.day)
      : await _deleteAppOwnedHealthWeight(
          ref: ref,
          sample: weightDay.healthSample,
        );
  if (deleted) {
    _refreshWeightDependents(
      ref,
      selectedDay: selectedDay,
      day: weightDay.day,
    );
  }
  return deleted;
}

Future<bool> _deleteAppOwnedHealthWeight({
  required WidgetRef ref,
  required HealthWeightSample? sample,
}) async {
  if (sample == null || !sample.isFromThisApp) {
    return false;
  }
  return ref.read(healthWeightServiceProvider).deleteWeightSample(sample);
}

void _refreshWeightDependents(
  WidgetRef ref, {
  required DateTime selectedDay,
  DateTime? day,
}) {
  ref
    ..invalidate(diaryActivityWeightDataProvider(selectedDay))
    ..invalidate(calorieHealthTrendSnapshotProvider)
    ..invalidate(calorieWeeklyCheckInViewModelProvider);
  if (day != null && !isSameDiaryDay(day, selectedDay)) {
    ref.invalidate(diaryActivityWeightDataProvider(day));
  }
}

Future<void> _showWeightDialog({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime selectedDay,
  required DateTime day,
  required double? initialWeightKg,
  required bool canClearWeight,
  required HealthWeightSample? healthSample,
}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final dayLabel = DateFormat.yMMMd(locale).format(day);
  final controller = ref.read(
    manualHealthWeightEntriesControllerProvider.notifier,
  );

  return showCalorieHealthWeightDialog(
    context: context,
    dayLabel: dayLabel,
    initialWeightKg: initialWeightKg,
    hasManualWeight: canClearWeight,
    onSaveWeight: (weightKg) async {
      final saved = await controller.saveEntry(day: day, weightKg: weightKg);
      if (saved) {
        _refreshWeightDependents(
          ref,
          selectedDay: selectedDay,
          day: day,
        );
      }
      return saved;
    },
    onClearWeight: () async {
      final deleted = healthSample?.isFromThisApp == true
          ? await _deleteAppOwnedHealthWeight(
              ref: ref,
              sample: healthSample,
            )
          : await controller.deleteEntryForDay(day);
      if (deleted) {
        _refreshWeightDependents(
          ref,
          selectedDay: selectedDay,
          day: day,
        );
      }
      return deleted;
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

    return DiaryDetailCardShell(
      child: _WeightDetailsContent(
        days: days,
        onAdd: () => unawaited(
          _showWeightDialog(
            context: context,
            ref: ref,
            selectedDay: normalizedSelectedDay,
            day: normalizedSelectedDay,
            initialWeightKg: data.selectedWeightKg,
            canClearWeight: selectedWeightDay?.canDeleteWeight ?? false,
            healthSample: selectedWeightDay?.healthSample,
          ),
        ),
        onEdit: (weightDay) => unawaited(
          _showWeightDialog(
            context: context,
            ref: ref,
            selectedDay: normalizedSelectedDay,
            day: weightDay.day,
            initialWeightKg: weightDay.weightKg,
            canClearWeight: weightDay.canDeleteWeight,
            healthSample: weightDay.healthSample,
          ),
        ),
        onDelete: (weightDay) => unawaited(
          _deleteWeight(
            ref: ref,
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
    final weightFormat = NumberFormat(
      '0.#',
      Localizations.localeOf(context).toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trending_down_rounded,
              color: Color(0xFF3B82F6),
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

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF3B82F6),
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
    final hasWeight = day.weightKg != null;

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
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
                  color: const Color(0xFF3B82F6),
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
