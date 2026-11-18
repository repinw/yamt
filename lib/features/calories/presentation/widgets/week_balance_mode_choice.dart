import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_week_card_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/application/calorie_budget_settings_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The three modes of the week balance as radio options, each with its line;
/// the one of the account is marked, and a tap picks another (#911). The
/// week card's menu and the settings show it. Keeps the room of the
/// options while the settings load. [onPicked] runs after a tap saved the mode.
class WeekBalanceModeChoice extends ConsumerWidget {
  /// Creates the choice.
  const new({this.onPicked, super.key});

  /// Called after the mode was picked.
  final VoidCallback? onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ref
        .watch(calorieGoalControllerProvider)
        .when(
          skipLoadingOnReload: true,
          // Keeps the room of the options, so the page does not jump when the
          // settings load.
          loading: () => SizedBox(
            height: AppWeekCard.optionHeight * WeekBalanceMode.values.length,
          ),
          error: (_, _) => Text(
            l10n.calorieGoalLoadFailed,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: FoodLabelColors.of(context).muted),
          ),
          data: (stored) => _options(context, ref, stored),
        );
  }

  Widget _options(
    BuildContext context,
    WidgetRef ref,
    CalorieGoalSettings stored,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // The limit is the one the rule caps with: the goals that follow the
    // TDEE once they are computed.
    final budget = ref.watch(calorieBudgetSettingsProvider).value ?? stored;
    final limit =
        NumberFormat.decimalPattern(
          Localizations.localeOf(context).toLanguageTag(),
        ).format(
          budget
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
            key: WeekBalanceModeKeys.option(mode),
            label: label,
            hint: hint,
            isSelected: mode == stored.weekBalanceMode,
            onTap: () => unawaited(_pick(context, ref, mode)),
          ),
      ],
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    WeekBalanceMode mode,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .setWeekBalanceMode(mode);
    if (saved) {
      onPicked?.call();
      return;
    }
    messenger.showAppSnackBar(
      l10n.weekBalanceSaveFailed,
      tone: AppSnackBarTone.error,
    );
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
                            key: WeekBalanceModeKeys.selected,
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
