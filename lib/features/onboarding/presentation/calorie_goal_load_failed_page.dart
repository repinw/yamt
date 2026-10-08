import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/controllers/'
    'calorie_goal_load_failed_controller.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Gate shown when the router cannot tell whether the signed-in user finished
/// onboarding, for example offline on a new device. Sending the user into
/// onboarding instead would ask an onboarded user to set up a goal again.
///
/// The router leaves this page as soon as the state loads. When the settings
/// never load, for example because the stored document is broken, signing
/// out is the way off this page; nothing here overwrites the stored goal.
/// A guest gets no sign-out: it would lose the guest account and its data
/// for good, while the cause is often only a missing connection.
class CalorieGoalLoadFailedPage extends ConsumerWidget {
  /// Creates the page.
  const new({super.key});

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final controller = ref.read(
      calorieGoalLoadFailedControllerProvider.notifier,
    );
    if (await controller.signOut() || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.calorieGoalLoadFailedSignOutFailed,
      tone: AppSnackBarTone.error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isSigningOut = ref.watch(
      calorieGoalLoadFailedControllerProvider.select(
        (state) => state.isLoading,
      ),
    );
    final user = ref.watch(authStateChangesProvider).value;
    final canSignOut = user != null && !user.isAnonymous;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppInsets.pageLarge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.calorieGoalLoadFailed, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                key: CalorieGoalOnboardingKeys.loadFailedRetryAction,
                onPressed: isSigningOut
                    ? null
                    : () => ref.invalidate(
                        calorieGoalOnboardingCompletedProvider,
                      ),
                child: Text(l10n.calorieGoalLoadRetryAction),
              ),
              if (canSignOut) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  key: CalorieGoalOnboardingKeys.loadFailedSignOutAction,
                  onPressed: isSigningOut
                      ? null
                      : () => unawaited(_signOut(context, ref, l10n)),
                  child: Text(l10n.calorieGoalLoadFailedSignOutAction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
