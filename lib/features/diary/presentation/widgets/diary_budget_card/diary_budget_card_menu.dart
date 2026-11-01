import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_meal_shares_editor.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_sheet_frame.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the budget card's menu for a day with [targetKcal].
Future<void> showDiaryBudgetCardMenu(
  BuildContext context, {
  required double targetKcal,
}) => showDiaryDashboardSheet(
  context,
  (_) => DiaryBudgetCardMenu(targetKcal: targetKcal),
);

/// Content of the budget card's menu: whether today's kcal line marks where
/// the day should be by now, and while it does, the parts of the day that
/// set the marker.
class DiaryBudgetCardMenu extends ConsumerWidget {
  /// Creates the menu.
  const new({required this.targetKcal, super.key});

  /// The day's kcal target the split shows in kcal.
  final double targetKcal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final showPace = ref.watch(diaryPaceMarkerControllerProvider);

    return Column(
      key: DiaryBudgetCardKeys.menu,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        DiaryDashboardSheetHeading(
          icon: Icons.donut_large_outlined,
          label: l10n.diaryBudgetMenuTitle,
        ),
        AppSwitchListTile(
          key: DiaryBudgetCardKeys.paceSwitch,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.diaryBudgetMenuPace),
          subtitle: Text(l10n.diaryBudgetMenuPaceHint),
          value: showPace,
          onChanged: (visible) => unawaited(
            ref
                .read(diaryPaceMarkerControllerProvider.notifier)
                .show(visible: visible),
          ),
        ),
        // The parts of the day only move the marker, so they come with it.
        AnimatedSize(
          duration: AppDurations.compactMetricExpansion,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: showPace
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.md,
                  children: [
                    Text(
                      l10n.diaryMealSharesTitle.toUpperCase(),
                      style: context.graphitKickerStyle,
                    ),
                    DiaryMealSharesEditor(targetKcal: targetKcal),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
