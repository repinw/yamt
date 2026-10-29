import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_budget_eaten_view_controller.dart';
import 'package:yamt/features/diary/presentation/diary_day_type_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Top row of the budget card: the "Übrig | Gegessen" switch, and the
/// training and pause buttons on the right. No pressed button is a normal
/// day.
///
/// The pause button's tap area reaches [AppBudgetCard.dayTypeHitOverhang]
/// past its visible edge, so the card gives this row that much more room at
/// the end than its other rows.
class DiaryBudgetToggleRow extends ConsumerWidget {
  /// Creates the row for [day].
  const new({required this.day, required this.showViewSwitch, super.key});

  /// Day of the card.
  final DateTime day;

  /// Whether the row shows the view switch; a pause day only shows eaten.
  final bool showViewSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(diaryDayTypeStatusProvider(day));

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: showViewSwitch ? const _ViewSwitch() : null,
          ),
        ),
        if (status != null)
          for (final (type, hitPadding) in _dayTypeButtons)
            _DayTypeButton(
              type: type,
              hitPadding: hitPadding,
              selected: status.type == type,
              onTap: () => unawaited(
                selectDiaryDayTypeFlow(
                  context,
                  ref,
                  day: day,
                  type: status.type == type ? DiaryDayType.normal : type,
                ),
              ),
            ),
      ],
    );
  }
}

/// "Übrig | Gegessen": whether the card's numbers show what is left or what
/// was eaten. Each segment's tap area is 48 high around the 36 high track.
class _ViewSwitch extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final showEaten = ref.watch(diaryBudgetEatenViewControllerProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: (AppSizes.minTapTarget - AppBudgetCard.viewSwitch) / 2,
            ),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.paper,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppBudgetCard.viewSwitchInset,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (eaten, label) in [
                (false, l10n.diaryBudgetViewLeft),
                (true, l10n.diaryBudgetViewEaten),
              ])
                _ViewSegment(
                  key: DiaryBudgetCardKeys.viewSegment(eaten: eaten),
                  label: label,
                  selected: showEaten == eaten,
                  onTap: () {
                    final view = ref.read(
                      diaryBudgetEatenViewControllerProvider.notifier,
                    );
                    eaten ? view.showEaten() : view.showLeft();
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewSegment extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return Semantics(
      button: true,
      selected: selected,
      onTap: onTap,
      child: AppInkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: selected ? colors.tile : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight:
                        AppBudgetCard.viewSwitch -
                        2 * AppBudgetCard.viewSwitchInset,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontFamily: AppFonts.geist,
                        fontWeight: FontWeight.w600,
                        color: selected ? colors.ink : colors.muted,
                      ),
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

/// The day type buttons with their tap padding: only [AppBudgetCard.dayTypeGap]
/// shows between them, the rest of each 48 wide tap reaches outward.
const List<(DiaryDayType, EdgeInsetsDirectional)> _dayTypeButtons = [
  (
    DiaryDayType.training,
    EdgeInsetsDirectional.only(
      start: AppBudgetCard.dayTypeHitOverhang,
      end: AppBudgetCard.dayTypeGap / 2,
    ),
  ),
  (
    DiaryDayType.pause,
    EdgeInsetsDirectional.only(
      start: AppBudgetCard.dayTypeGap / 2,
      end: AppBudgetCard.dayTypeHitOverhang,
    ),
  ),
];

/// Round training or pause button; pressed, it widens and shows its word.
/// [hitPadding] widens the tap area past the visible button.
class _DayTypeButton extends StatelessWidget {
  const new({
    required this.type,
    required this.hitPadding,
    required this.selected,
    required this.onTap,
  });

  final DiaryDayType type;
  final EdgeInsetsDirectional hitPadding;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final foreground = selected ? colors.tile : colors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: diaryDayTypeLabel(type, l10n),
      onTap: onTap,
      excludeSemantics: true,
      child: AppInkWell(
        key: DiaryBudgetCardKeys.dayTypeButton(type),
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: hitPadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
            child: Center(
              widthFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: selected ? colors.ink : colors.paper,
                  shape: const StadiumBorder(),
                ),
                child: Padding(
                  padding: selected
                      ? const EdgeInsetsDirectional.only(
                          start: AppSpacing.xs,
                          end: AppSpacing.md,
                        )
                      : EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppBudgetCard.dayButton,
                      minHeight: AppBudgetCard.dayButton,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: AppSpacing.xxs,
                      children: [
                        Icon(
                          diaryBudgetDayTypeIcon(type),
                          size: AppBudgetCard.dayIcon,
                          color: foreground,
                        ),
                        if (selected)
                          Text(
                            diaryDayTypeShortLabel(type, l10n),
                            style: Theme.of(context).textTheme.labelMedium
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

/// Icon of a day type in the budget card.
IconData diaryBudgetDayTypeIcon(DiaryDayType type) => switch (type) {
  DiaryDayType.training => Icons.fitness_center_rounded,
  DiaryDayType.normal => Icons.radio_button_unchecked_rounded,
  DiaryDayType.pause => Icons.pause_rounded,
};
