import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_previous_day_controller.dart';
import 'package:yamt/features/diary/presentation/diary_previous_day_flow.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Closes the day before a planned day, so the planned day gets the
/// carryover of that day. Once closed, it says so and offers to reopen.
class DiaryPreviousDayRow extends ConsumerWidget {
  /// Creates the row for [data], whose previous day can be closed.
  const new({required this.data, super.key});

  /// Render-ready card data with a previous-day carryover.
  final DiaryDailyBalanceData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final mono = Theme.of(context).textTheme.labelSmall
        ?.copyWith(fontFamily: AppFonts.mono, color: colors.muted);
    final previousDay = previousDiaryDay(data.selectedDay);
    final weekday = DateFormat(
      'EEEE',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(previousDay);
    final perDay = l10n.diaryPreviousDayCarryoverPerDay(
      data.previousDayCarryoverValue!,
    );
    final isSaving = ref.watch(
      diaryPreviousDayControllerProvider.select((state) => state.isLoading),
    );

    if (data.isPreviousDayClosed) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.xs,
        children: [
          Row(
            key: DiaryBalanceCardKeys.previousDayClosed,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSizes.compactMetricIconLabelGap,
            children: [
              Icon(
                Icons.check_rounded,
                size: AppSizes.compactMetricIcon,
                color: colors.accentText,
              ),
              Flexible(
                child: Text(
                  l10n.diaryPreviousDayClosed(weekday),
                  style: mono?.copyWith(color: colors.accentText),
                ),
              ),
            ],
          ),
          Text(perDay, style: mono),
          TextButton(
            key: DiaryBalanceCardKeys.previousDayReopenButton,
            onPressed: isSaving
                ? null
                : () => unawaited(
                    reopenDiaryPreviousDayFlow(context, ref, weekday: weekday),
                  ),
            child: Text(l10n.diaryPreviousDayReopenAction(weekday)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        OutlinedButton.icon(
          key: DiaryBalanceCardKeys.previousDayCloseButton,
          style: OutlinedButton.styleFrom(
            alignment: AlignmentDirectional.centerStart,
            minimumSize: const Size.fromHeight(AppSizes.minTapTarget),
            foregroundColor: colors.ink,
            side: BorderSide(
              color: colors.accentText,
              width: AppFoodLabel.outline,
            ),
          ),
          onPressed: isSaving
              ? null
              : () => unawaited(
                  closeDiaryPreviousDayFlow(
                    context,
                    ref,
                    day: previousDay,
                    weekday: weekday,
                  ),
                ),
          icon: const Icon(Icons.check_rounded),
          label: Text(l10n.diaryPreviousDayCloseAction(weekday)),
        ),
        Text(perDay, style: mono),
      ],
    );
  }
}
