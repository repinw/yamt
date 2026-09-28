import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_qr_code.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_invite_code_controller.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Lets the admin create an invite and shows it as a QR code and a link.
class HouseholdInviteSection extends ConsumerWidget {
  /// Creates the section.
  const new({required this.isBusy, super.key});

  /// Key of the button that creates an invite.
  static const createKey = Key('household_invite_create');

  /// Whether a household action runs.
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inviteState = ref.watch(householdInviteCodeControllerProvider);
    final invite = inviteState.asData?.value;

    if (invite != null) {
      return _GeneratedInviteView(invite: invite, isBusy: isBusy);
    }
    return FilledButton.icon(
      key: createKey,
      onPressed: isBusy ? null : () => _generateInviteCode(context, ref, l10n),
      icon: inviteState.isLoading
          ? const SizedBox.square(
              dimension: AppSizes.inlineProgressIndicator,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.progressStrokeWidth,
              ),
            )
          : const Icon(Icons.qr_code_2_outlined),
      label: Text(l10n.householdInviteCreate),
    );
  }

  Future<void> _generateInviteCode(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      await ref
          .read(householdInviteCodeControllerProvider.notifier)
          .generateInviteCode();
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showAppSnackBar(
        householdErrorMessage(l10n, error),
        tone: AppSnackBarTone.error,
      );
    }
  }
}

class _GeneratedInviteView extends ConsumerWidget {
  const new({required this.invite, required this.isBusy});

  final HouseholdInvite invite;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: AppQrCode(
            data: invite.link,
            size: AppSizes.householdInviteQrCode,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(
            l10n.householdInviteValidFor,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: invite.link));
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context)
                      .showAppSnackBar(l10n.householdInviteLinkCopied);
                },
                icon: const Icon(Icons.link),
                label: Text(l10n.householdInviteCopyLink),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: isBusy
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(
                              householdInviteCodeControllerProvider.notifier,
                            )
                            .generateInviteCode();
                      } on Object catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showAppSnackBar(
                          householdErrorMessage(l10n, error),
                          tone: AppSnackBarTone.error,
                        );
                      }
                    },
              icon: const Icon(Icons.refresh),
              tooltip: l10n.householdInviteRefresh,
            ),
          ],
        ),
      ],
    );
  }
}
