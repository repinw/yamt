import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_plan_color_controller.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_plan_color_tile/settings_plan_color_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row that shows the current plan color and opens the picker.
class SettingsPlanColorTile extends ConsumerWidget {
  /// Creates the plan color row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isCustom = ref.watch(appPlanColorControllerProvider) != null;

    return SettingsTile(
      key: SettingsPageKeys.planColorTile,
      icon: Icons.event_note_outlined,
      title: l10n.settingsPlanColorTitle,
      trailing: SettingsTrailingValue(
        value: isCustom
            ? l10n.settingsPlanColorCustom
            : l10n.settingsPlanColorDefault,
        swatchColor: FoodLabelColors.of(context).plan,
      ),
      onTap: () => unawaited(showSettingsPlanColorSheet(context)),
    );
  }
}
