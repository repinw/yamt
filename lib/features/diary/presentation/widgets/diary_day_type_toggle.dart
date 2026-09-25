import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Day type chip in the diary top bar: the short name in small capitals
/// inside a thin frame. A tap opens the day type sheet.
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

    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    return Tooltip(
      message: diaryDayTypeLabel(status.type, l10n),
      child: AppInkWell(
        key: buttonKey,
        onTap: () => unawaited(
          showDiaryDayTypeSheet(context: context, selectedDay: selectedDay),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.ink,
                  width: AppFoodLabel.chipOutline,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                child: Text(
                  diaryDayTypeShortLabel(status.type, l10n).toUpperCase(),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: AppFonts.mono,
                    color: colors.ink,
                    letterSpacing: AppFoodLabel.navLabelTracking,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
