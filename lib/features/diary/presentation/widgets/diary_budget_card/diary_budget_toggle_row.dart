import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_budget_eaten_view_controller.dart';
import 'package:yamt/features/diary/presentation/diary_day_type_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_day_type_buttons.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_view_switch.dart';

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
    final showEaten = ref.watch(diaryBudgetEatenViewControllerProvider);

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: showViewSwitch
                ? DiaryBudgetViewSwitch(
                    showEaten: showEaten,
                    onSelect: (eaten) {
                      final view = ref.read(
                        diaryBudgetEatenViewControllerProvider.notifier,
                      );
                      eaten ? view.showEaten() : view.showLeft();
                    },
                  )
                : null,
          ),
        ),
        if (status != null)
          DiaryBudgetDayTypeButtons(
            selected: status.type,
            onSelect: (type) => unawaited(
              selectDiaryDayTypeFlow(context, ref, day: day, type: type),
            ),
          ),
      ],
    );
  }
}
