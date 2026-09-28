import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_membership_controller.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Takes the household key back after a fresh start: the user types the
/// unlock code that another member created.
class HouseholdKeyRestoreSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const new({required this.isBusy, super.key});

  /// Whether a household action runs.
  final bool isBusy;

  /// Key of the code field.
  static const codeFieldKey = Key('household_key_restore_code_field');

  /// Key of the button that restores the key.
  static const restoreButtonKey = Key('household_key_restore_button');

  @override
  ConsumerState<HouseholdKeyRestoreSection> createState() =>
      _HouseholdKeyRestoreSectionState();
}

class _HouseholdKeyRestoreSectionState
    extends ConsumerState<HouseholdKeyRestoreSection> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.householdKeyRestoreSelfMessage),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: HouseholdKeyRestoreSection.codeFieldKey,
          controller: _codeController,
          enabled: !widget.isBusy,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: l10n.householdKeyRestoreCodeLabel,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          key: HouseholdKeyRestoreSection.restoreButtonKey,
          onPressed: widget.isBusy ? null : () => _restore(l10n),
          child: Text(l10n.householdKeyRestoreAction),
        ),
      ],
    );
  }

  Future<void> _restore(AppLocalizations l10n) async {
    try {
      await ref
          .read(householdMembershipControllerProvider.notifier)
          .restoreHouseholdKey(_codeController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showAppSnackBar(l10n.householdKeyRestoreSuccess);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showAppSnackBar(
        householdErrorMessage(l10n, error),
        tone: AppSnackBarTone.error,
      );
    }
  }
}
