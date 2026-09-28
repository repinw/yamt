import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/household/domain/household_member.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_membership_controller.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/features/household/presentation/models/household_member_label.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Hands the household key to [member], who lost it after a fresh start:
/// creates a one-time unlock code to pass on.
class HouseholdUnlockCodeSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const new({required this.member, required this.isBusy, super.key});

  /// The member who waits for the key.
  final HouseholdMember member;

  /// Whether a household action runs.
  final bool isBusy;

  /// Key of the button that creates a code.
  static const createCodeButtonKey = Key('household_unlock_code_create');

  /// Key of the created code.
  static const createdCodeKey = Key('household_unlock_code_created');

  @override
  ConsumerState<HouseholdUnlockCodeSection> createState() =>
      _HouseholdUnlockCodeSectionState();
}

class _HouseholdUnlockCodeSectionState
    extends ConsumerState<HouseholdUnlockCodeSection> {
  RecoveryKey? _createdCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = householdMemberLabel(widget.member, l10n);
    final createdCode = _createdCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.householdKeyRestoreMemberMessage(name)),
        const SizedBox(height: AppSpacing.md),
        if (createdCode == null)
          FilledButton(
            key: HouseholdUnlockCodeSection.createCodeButtonKey,
            onPressed: widget.isBusy ? null : () => _createCode(l10n),
            child: Text(l10n.householdKeyRestoreCreateAction),
          )
        else ...[
          SelectableText(
            createdCode.formatted,
            key: HouseholdUnlockCodeSection.createdCodeKey,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.householdKeyRestoreCodeHint(name)),
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

  Future<void> _createCode(AppLocalizations l10n) async {
    try {
      final code = await ref
          .read(householdMembershipControllerProvider.notifier)
          .createKeyRestoreCode(widget.member.uid);
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
