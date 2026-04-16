import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/household/presentation/household_error_message.dart';
import 'package:yamt/features/household/provider/'
    'household_membership_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines household join section.
class HouseholdJoinSection extends ConsumerStatefulWidget {
  /// The household join section.
  const HouseholdJoinSection({super.key, required this.isBusy});

  /// Whether busy.
  final bool isBusy;

  @override
  ConsumerState<HouseholdJoinSection> createState() =>
      _HouseholdJoinSectionState();
}

class _HouseholdJoinSectionState extends ConsumerState<HouseholdJoinSection> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
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
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: l10n.householdJoinCodeLabel,
                  hintText: l10n.householdJoinCodeHint,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _codeController,
              builder: (context, value, _) {
                final isReady = value.text.trim().length == 6;
                return FilledButton(
                  onPressed: widget.isBusy || !isReady
                      ? null
                      : () => _joinHousehold(context, l10n),
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

  Future<void> _joinHousehold(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(householdMembershipControllerProvider.notifier)
          .joinHousehold(_codeController.text);
      if (!mounted) {
        return;
      }
      _codeController.clear();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.householdJoinSuccess)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(householdErrorMessage(l10n, error))),
      );
    }
  }
}
