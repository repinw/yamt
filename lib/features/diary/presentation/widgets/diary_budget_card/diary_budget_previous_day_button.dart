import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_previous_day_controller.dart';
import 'package:yamt/features/diary/presentation/diary_previous_day_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Closes the day before [day], so [day] gets that day's carryover. Once
/// closed it says so, and a tap opens the day before again.
class DiaryBudgetPreviousDayButton extends ConsumerWidget {
  /// Creates the button for [day].
  const new({required this.day, required this.isClosed, super.key});

  /// Day of the card; the day before it is closed.
  final DateTime day;

  /// Whether the day before is closed.
  final bool isClosed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final previousDay = previousLocalDay(day);
    final weekday = DateFormat.EEEE(locale).format(previousDay);
    final isSaving = ref.watch(
      diaryPreviousDayControllerProvider.select((state) => state.isLoading),
    );
    final background = isClosed ? Colors.transparent : colors.ink;
    final foreground = isClosed ? colors.muted : colors.tile;

    final onTap = isSaving
        ? null
        : () => unawaited(
            isClosed
                ? reopenDiaryPreviousDayFlow(context, ref, weekday: weekday)
                : closeDiaryPreviousDayFlow(
                    context,
                    ref,
                    day: previousDay,
                    weekday: weekday,
                  ),
          );

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        button: true,
        label: isClosed
            ? l10n.diaryPreviousDayReopenAction(weekday)
            : l10n.diaryPreviousDayCloseAction(weekday),
        onTap: onTap,
        excludeSemantics: true,
        child: AppInkWell(
          key: isClosed
              ? DiaryBudgetCardKeys.reopenPreviousDay
              : DiaryBudgetCardKeys.closePreviousDay,
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
            child: Center(
              widthFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: background,
                  shape: StadiumBorder(
                    side: isClosed
                        ? BorderSide(
                            color: colors.track,
                            width: AppBudgetCard.chipOutline,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.sm,
                    end: AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppBudgetCard.chip,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.xxs,
                      children: [
                        Icon(
                          isClosed ? Icons.check_rounded : Icons.lock_rounded,
                          size: AppBudgetCard.chipIcon,
                          color: isClosed ? colors.accentText : foreground,
                        ),
                        Text(
                          isClosed
                              ? l10n.diaryPreviousDayClosed(weekday)
                              : l10n.diaryPreviousDayCloseAction(weekday),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontFamily: AppFonts.geist,
                                fontWeight: FontWeight.w600,
                                color: foreground,
                              ),
                        ),
                      ],
                    ),
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
