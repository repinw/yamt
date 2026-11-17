import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_week_card_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The three modes of the week balance as radio options, each with its line;
/// the one of the account is marked, and a tap picks another (#911). The
/// week card's menu and the settings show it. Shows nothing while the
/// settings load. [onPicked] runs after a tap saved the mode.
class WeekBalanceModeChoice extends ConsumerWidget {
  /// Creates the choice.
  const new({this.onPicked, super.key});

  /// Called after the mode was picked.
  final VoidCallback? onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(calorieGoalControllerProvider).value;
    if (settings == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final limit =
        NumberFormat.decimalPattern(
          Localizations.localeOf(context).toLanguageTag(),
        ).format(
          settings
              .carryoverLimitKcalForDay(ref.watch(diaryTodayProvider))
              .round(),
        );
    final options = <WeekBalanceMode, (String, String)>{
      WeekBalanceMode.off: (l10n.weekBalanceOff, l10n.weekBalanceOffHint),
      WeekBalanceMode.show: (l10n.weekBalanceShow, l10n.weekBalanceShowHint),
      WeekBalanceMode.carryover: (
        l10n.weekBalanceCarryover,
        l10n.weekBalanceCarryoverHint(limit),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final MapEntry(key: mode, value: (label, hint)) in options.entries)
          _Option(
            key: DiaryWeekCardKeys.modeOption(mode),
            label: label,
            hint: hint,
            isSelected: mode == settings.weekBalanceMode,
            onTap: () => unawaited(_pick(ref, mode)),
          ),
      ],
    );
  }

  Future<void> _pick(WidgetRef ref, WeekBalanceMode mode) async {
    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .setWeekBalanceMode(mode);
    if (saved) {
      onPicked?.call();
    }
  }
}

/// One option: a mark, its name and its line.
class _Option extends StatelessWidget {
  const new({
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String hint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      child: AppInkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppWeekCard.optionHeight,
          ),
          child: Row(
            spacing: AppWeekCard.optionGap,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.ink : colors.muted,
                    width: AppWeekCard.optionRing,
                  ),
                ),
                child: SizedBox.square(
                  dimension: AppWeekCard.optionMark,
                  child: isSelected
                      ? Center(
                          child: DecoratedBox(
                            key: DiaryWeekCardKeys.modeSelected,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.ink,
                            ),
                            child: const SizedBox.square(
                              dimension: AppWeekCard.optionDot,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleSmall?.copyWith(
                        fontFamily: AppFonts.geist,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      hint,
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: AppFonts.geist,
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
