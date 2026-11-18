import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/presentation/widgets/week_balance_mode_choice.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_sheet_frame.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the week card's menu.
Future<void> showDiaryWeekCardMenu(BuildContext context) =>
    showDiaryDashboardSheet(context, (_) => const DiaryWeekCardMenu());

/// Content of the week card's menu: the choice of the mode and where to
/// change it later. A pick closes the menu.
class DiaryWeekCardMenu extends StatelessWidget {
  /// Creates the menu.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      key: DiaryWeekCardKeys.menu,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        DiaryDashboardSheetHeading(
          icon: Icons.calendar_month_outlined,
          label: l10n.weekBalanceTitle,
        ),
        WeekBalanceModeChoice(
          onPicked: () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        Text(
          l10n.weekBalanceChangeLater,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: FoodLabelColors.of(context).muted),
        ),
      ],
    );
  }
}
