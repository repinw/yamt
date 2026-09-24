import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/pending_household_invite.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_membership_controller.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_invite_scanner.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_join_name_dialog/household_join_name_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines household join section.
class HouseholdJoinSection extends ConsumerStatefulWidget {
  /// The household join section.
  const new({required this.isBusy, super.key});

  /// Whether busy.
  final bool isBusy;

  @override
  ConsumerState<HouseholdJoinSection> createState() =>
      _HouseholdJoinSectionState();
}

class _HouseholdJoinSectionState extends ConsumerState<HouseholdJoinSection> {
  final TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // A deep link fills the form after the first frame, because taking the
    // invite changes a provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final invite = ref.read(pendingHouseholdInviteProvider.notifier).take();
      if (invite != null) {
        _linkController.text = invite.link;
      }
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final membershipState = ref.watch(householdMembershipControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.householdJoinTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: l10n.householdJoinLinkLabel,
                  hintText: l10n.householdJoinLinkHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: widget.isBusy
                        ? null
                        : () => _scanInvite(context, l10n),
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: l10n.householdJoinScanQr,
                  ),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _linkController,
              builder: (context, value, _) {
                final invite = HouseholdInvite.tryParse(value.text);
                return FilledButton(
                  onPressed: widget.isBusy || invite == null
                      ? null
                      : () => _joinHousehold(context, l10n, invite),
                  child: membershipState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.householdJoinAction),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _scanInvite(BuildContext context, AppLocalizations l10n) async {
    final invite = await openHouseholdInviteScanner(context);
    if (invite == null || !context.mounted) {
      return;
    }
    _linkController.text = invite.link;
    await _joinHousehold(context, l10n, invite);
  }

  Future<void> _joinHousehold(
    BuildContext context,
    AppLocalizations l10n,
    HouseholdInvite invite,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final profile = ref.read(userProfileProvider).asData?.value;
    final currentUser = ref.read(authStateChangesProvider).asData?.value;
    final currentName = (profile?.displayName ?? currentUser?.displayName)
        ?.trim();
    String? nameToSet;

    if (currentName == null || currentName.isEmpty) {
      nameToSet = await showHouseholdJoinNameDialog(
        context: context,
        l10n: l10n,
      );
      if (nameToSet == null || nameToSet.trim().isEmpty) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    try {
      await ref
          .read(householdMembershipControllerProvider.notifier)
          .joinHousehold(invite, displayName: nameToSet);
      if (!mounted) {
        return;
      }
      _linkController.clear();
      messenger.showAppSnackBar(l10n.householdJoinSuccess);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showAppSnackBar(
        householdErrorMessage(l10n, error),
        tone: AppSnackBarTone.error,
      );
    }
  }
}
