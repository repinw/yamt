import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/features/household/provider/'
    'household_invite_code_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines household invite section.
class HouseholdInviteSection extends ConsumerWidget {
  /// The household invite section.
  const HouseholdInviteSection({required this.isBusy, super.key});

  /// Whether busy.
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inviteState = ref.watch(householdInviteCodeControllerProvider);
    final code = inviteState.asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.householdInviteTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (code == null)
          FilledButton.icon(
            onPressed: isBusy
                ? null
                : () => _generateInviteCode(context, ref, l10n),
            icon: inviteState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_2_outlined),
            label: Text(l10n.householdInviteGenerateCode),
          )
        else
          _GeneratedCodeView(code: code, isBusy: isBusy),
      ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(householdErrorMessage(l10n, error))),
      );
    }
  }
}

class _GeneratedCodeView extends ConsumerWidget {
  const _GeneratedCodeView({required this.code, required this.isBusy});

  final String code;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              children: [
                Text(
                  code,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.householdInviteCodeValidFor),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.householdInviteCodeCopied)),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.householdInviteCopyCode),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(householdErrorMessage(l10n, error)),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.refresh),
              tooltip: l10n.householdInviteRefreshCode,
            ),
          ],
        ),
      ],
    );
  }
}
