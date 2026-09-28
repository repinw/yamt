import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_membership_controller.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Hands the household key back to a host who started fresh.
///
/// The host types the restore code here; a member creates it.
class HouseholdKeyRestoreSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const new({required this.isHost, required this.isBusy, super.key});

  /// Whether the user is the host who lost the key.
  final bool isHost;

  /// Whether a household action runs.
  final bool isBusy;

  /// Key of the code field.
  static const codeFieldKey = Key('household_key_restore_code_field');

  /// Key of the button that restores the key.
  static const restoreButtonKey = Key('household_key_restore_button');

  /// Key of the button that creates a code.
  static const createCodeButtonKey = Key('household_key_restore_create_button');

  /// Key of the created code.
  static const createdCodeKey = Key('household_key_restore_created_code');

  @override
  ConsumerState<HouseholdKeyRestoreSection> createState() =>
      _HouseholdKeyRestoreSectionState();
}

class _HouseholdKeyRestoreSectionState
    extends ConsumerState<HouseholdKeyRestoreSection> {
  final _codeController = TextEditingController();
  RecoveryKey? _createdCode;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final createdCode = _createdCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isHost
              ? l10n.householdKeyRestoreHostMessage
              : l10n.householdKeyRestoreMemberMessage,
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.isHost) ...[
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
        ] else if (createdCode == null)
          FilledButton(
            key: HouseholdKeyRestoreSection.createCodeButtonKey,
            onPressed: widget.isBusy ? null : () => _createCode(l10n),
            child: Text(l10n.householdKeyRestoreCreateAction),
          )
        else ...[
          SelectableText(
            createdCode.formatted,
            key: HouseholdKeyRestoreSection.createdCodeKey,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.householdKeyRestoreCodeHint),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => _copy(createdCode, l10n),
            icon: const Icon(Icons.copy_outlined),
            label: Text(l10n.householdKeyRestoreCopyAction),
          ),
        ],
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

  Future<void> _createCode(AppLocalizations l10n) async {
    try {
      final code = await ref
          .read(householdMembershipControllerProvider.notifier)
          .createKeyRestoreCode();
      if (!mounted) return;
      setState(() => _createdCode = code);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showAppSnackBar(
        householdErrorMessage(l10n, error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _copy(RecoveryKey code, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: code.formatted));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showAppSnackBar(l10n.householdKeyRestoreCopied);
  }
}
