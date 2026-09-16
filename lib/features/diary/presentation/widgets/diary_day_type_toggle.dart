import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Single-emoji day type button shown in the diary top bar actions.
class DiaryDayTypeToggle extends ConsumerWidget {
  /// Creates the diary day type toggle.
  const DiaryDayTypeToggle({super.key});

  /// Key of the tappable emoji button.
  static const buttonKey = ValueKey<String>('diary-day-type-toggle');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(diaryCalendarControllerProvider).selectedDay;
    final status = ref.watch(diaryDayTypeStatusProvider(selectedDay));
    if (status == null) {
      return const SizedBox.shrink();
    }

    return IconButton(
      key: buttonKey,
      tooltip: diaryDayTypeLabel(status.type, AppLocalizations.of(context)!),
      onPressed: () => unawaited(
        showDiaryDayTypeSheet(context: context, selectedDay: selectedDay),
      ),
      icon: Text(
        diaryDayTypeEmoji(status.type),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
