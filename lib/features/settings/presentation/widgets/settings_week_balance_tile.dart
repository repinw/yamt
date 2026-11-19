import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/presentation/widgets/week_balance_menu.dart';
import 'package:yamt/features/calories/presentation/widgets/week_balance_mode_choice.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row of the week balance (#911): the chosen mode as its subtitle;
/// a tap opens the menu with the choice, the same as the diary's week card.
class SettingsWeekBalanceTile extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(
      calorieGoalControllerProvider.select(
        (settings) => settings.value?.weekBalanceMode,
      ),
    );

    return SettingsTile(
      key: SettingsPageKeys.weekBalanceTile,
      icon: Icons.calendar_month_outlined,
      title: l10n.weekBalanceTitle,
      subtitle: mode?.label(l10n),
      onTap: () =>
          unawaited(showWeekBalanceMenu(context, showChangeLater: false)),
    );
  }
}
