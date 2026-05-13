import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/presentation/calorie_goal_onboarding_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Expanded section shown when future start is selected.
class Step6FutureStartSection extends StatelessWidget {
  /// Creates future-start section.
  const Step6FutureStartSection({
    required this.futureGoalStartDate,
    required this.onFutureGoalStartChangeRequested,
    super.key,
  });

  /// Selected future start date.
  final DateTime futureGoalStartDate;

  /// Called when user wants to change future start date.
  final VoidCallback onFutureGoalStartChangeRequested;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(futureGoalStartDate),
            key: CalorieGoalOnboardingKeys.goalStartValue,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.caloriesCalculatorOnboardingStartLaterHint,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: CalorieGoalOnboardingKeys.goalStartChangeButton,
            onPressed: onFutureGoalStartChangeRequested,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              l10n.caloriesCalculatorOnboardingChooseFutureDateAction,
            ),
          ),
        ],
      ),
    );
  }
}
