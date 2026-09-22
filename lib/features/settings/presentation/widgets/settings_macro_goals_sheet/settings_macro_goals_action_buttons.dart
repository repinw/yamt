import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_sheet_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Action buttons for saving macro distribution or resetting to
/// recommendations.
class SettingsMacroGoalsActionButtons extends StatelessWidget {
  /// Creates the macro goals action buttons.
  const new({
    required this.onSave,
    required this.onReset,
    super.key,
  });

  /// Callback when save button is pressed.
  final VoidCallback onSave;

  /// Callback when reset button is pressed.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: SettingsMacroGoalsSheetKeys.saveButton,
          onPressed: onSave,
          child: Text(l10n.settingsMacroGoalsSaveButton),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: TextButton.icon(
            key: SettingsMacroGoalsSheetKeys.resetButton,
            onPressed: onReset,
            icon: const Icon(Icons.restore_rounded, size: 18),
            label: Text(l10n.settingsMacroGoalsResetButton),
          ),
        ),
      ],
    );
  }
}
