import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the modal bottom sheet to select the day type (training, rest, pause).
Future<void> showDiaryDayTypeSheet({
  required BuildContext context,
  required DateTime selectedDay,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
    ),
    builder: (_) => DiaryDayTypeSheet(selectedDay: selectedDay),
  );
}

/// Day type picker for a single diary day.
class DiaryDayTypeSheet extends ConsumerWidget {
  /// Creates the day type picker.
  const DiaryDayTypeSheet({required this.selectedDay, super.key});

  /// Day whose type is changed.
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(diaryDayTypeStatusProvider(selectedDay));
    if (status == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.diaryDayTypeSheetTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.diaryDayTypeSheetBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            for (final type in DiaryDayType.values) ...[
              const SizedBox(height: AppSpacing.xs),
              _DiaryDayTypeOption(
                type: type,
                subtitle: _subtitleFor(type, status, l10n),
                isSelected: type == status.type,
                onTap: () => _select(context, ref, type),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitleFor(
    DiaryDayType type,
    DiaryDayTypeStatus status,
    AppLocalizations l10n,
  ) {
    return switch (type) {
      DiaryDayType.training when status.trainingDayKcalOffset > 0 =>
        l10n.diaryDayTypeTrainingOffsetSubtitle(
          status.trainingDayKcalOffset.toInt(),
        ),
      DiaryDayType.training => l10n.diaryDayTypeTrainingSubtitle,
      DiaryDayType.rest => l10n.diaryDayTypeRestSubtitle,
      DiaryDayType.pause => l10n.diaryDayTypePauseSubtitle,
    };
  }

  void _select(BuildContext context, WidgetRef ref, DiaryDayType type) {
    final updater = ref.read(diaryDayTypeUpdaterProvider);
    Navigator.of(context).pop();
    unawaited(updater.select(selectedDay, type));
  }
}

class _DiaryDayTypeOption extends StatelessWidget {
  const _DiaryDayTypeOption({
    required this.type,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final DiaryDayType type;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final color = switch (type) {
      DiaryDayType.training => colors.primary,
      DiaryDayType.rest => colors.secondary,
      DiaryDayType.pause => colors.tertiary,
    };

    return Material(
      color: isSelected
          ? color.withValues(alpha: 0.12)
          : colors.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AppInkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${diaryDayTypeEmoji(type)} '
                      '${diaryDayTypeLabel(type, l10n)}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected ? color : colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, size: 20, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
