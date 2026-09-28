import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/household/domain/household_member.dart';
import 'package:yamt/features/household/presentation/models/household_member_label.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What the user chose when leaving: the member who leads after them, or
/// `null` when they do not lead.
typedef HouseholdLeaveChoice = ({String? successorUid});

/// Asks the user to confirm leaving the active household. An admin also
/// picks who leads after them. Returns `null` when the user cancels.
Future<HouseholdLeaveChoice?> showHouseholdLeaveDialog(
  BuildContext context, {
  required List<HouseholdMember> members,
  required String currentUserId,
  required bool isOwnHousehold,
}) {
  return showDialog<HouseholdLeaveChoice>(
    context: context,
    builder: (_) => HouseholdLeaveDialog(
      members: members,
      currentUserId: currentUserId,
      isOwnHousehold: isOwnHousehold,
    ),
  );
}

/// Confirms leaving the household, with the choice of the next admin.
class HouseholdLeaveDialog extends StatefulWidget {
  /// Creates the dialog.
  const new({
    required this.members,
    required this.currentUserId,
    required this.isOwnHousehold,
    super.key,
  });

  /// Key of the confirm button.
  static const confirmKey = Key('household_leave_confirm');

  /// Key of the choice of [uid] as the next admin.
  static Key successorKey(String uid) =>
      ValueKey<String>('household_leave_successor_$uid');

  /// The members of the household, including the current user.
  final List<HouseholdMember> members;

  /// The user who leaves.
  final String currentUserId;

  /// Whether the user leaves their own household.
  final bool isOwnHousehold;

  @override
  State<HouseholdLeaveDialog> createState() => _HouseholdLeaveDialogState();
}

class _HouseholdLeaveDialogState extends State<HouseholdLeaveDialog> {
  String? _successorUid;

  @override
  void initState() {
    super.initState();
    final current = widget.members.firstWhereOrNull(
      (member) => member.uid == widget.currentUserId,
    );
    if (current?.isAdmin ?? false) {
      _successorUid = proposeSuccessor(
        widget.members,
        widget.currentUserId,
      )?.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final others = widget.members
        .where((member) => member.uid != widget.currentUserId)
        .toList(growable: false);
    final isLastMember = others.isEmpty;
    final message = isLastMember
        ? l10n.householdDeleteMessage
        : widget.isOwnHousehold
        ? l10n.householdLeaveOwnMessage
        : l10n.householdLeaveMessage;

    return AlertDialog(
      title: Text(
        isLastMember ? l10n.householdDeleteTitle : l10n.householdLeaveTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (_successorUid != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.householdLeaveSuccessorLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RadioGroup<String>(
                groupValue: _successorUid,
                onChanged: AppHapticFeedback.wrapValueChanged<String?>(
                  (uid) => setState(() => _successorUid = uid),
                )!,
                child: Column(
                  children: [
                    for (final member in others)
                      AppRadioListTile<String>(
                        key: HouseholdLeaveDialog.successorKey(member.uid),
                        value: member.uid,
                        contentPadding: EdgeInsets.zero,
                        title: Text(householdMemberLabel(member, l10n)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: HouseholdLeaveDialog.confirmKey,
          onPressed: () =>
              Navigator.of(context)
                  .pop<HouseholdLeaveChoice>((successorUid: _successorUid)),
          child: Text(
            isLastMember
                ? l10n.householdDeleteAction
                : l10n.householdLeaveAction,
          ),
        ),
      ],
    );
  }
}
