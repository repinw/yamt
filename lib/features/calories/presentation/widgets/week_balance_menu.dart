import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_dashboard_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/week_balance_mode_choice.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the menu of the week balance: the choice of the mode and where to
/// change it later. A pick closes the menu.
Future<void> showWeekBalanceMenu(BuildContext context) =>
    showAppDashboardSheet(context, (_) => const _WeekBalanceMenu());

class _WeekBalanceMenu extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      key: WeekBalanceModeKeys.menu,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        AppDashboardSheetHeading(
          icon: Icons.calendar_month_outlined,
          label: l10n.weekBalanceTitle,
        ),
        WeekBalanceModeChoice(
          onPicked: () {
            // A second pick while the sheet leaves must not pop the page
            // below it.
            if (context.mounted && ModalRoute.of(context)!.isCurrent) {
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
