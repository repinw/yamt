import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/food_label_icon_chip.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Day type chip in the diary top bar: the day type's icon in a frame. A
/// tap opens the day type sheet.
class DiaryDayTypeToggle extends ConsumerWidget {
  /// Creates the diary day type toggle.
  const new({super.key});

  /// Key of the tappable chip.
  static const buttonKey = ValueKey<String>('diary-day-type-toggle');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(diaryCalendarControllerProvider).selectedDay;
    final status = ref.watch(diaryDayTypeStatusProvider(selectedDay));
    if (status == null) {
      return const SizedBox.shrink();
    }

    return FoodLabelIconChip(
      key: buttonKey,
      icon: diaryDayTypeIcon(status.type),
      tooltip: diaryDayTypeLabel(status.type, AppLocalizations.of(context)!),
      onTap: () => unawaited(
        showDiaryDayTypeSheet(context: context, selectedDay: selectedDay),
      ),
    );
  }
}
