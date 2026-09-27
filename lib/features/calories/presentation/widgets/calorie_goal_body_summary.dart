import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The body data that a new goal uses, as a plain list, with a link that
/// closes the goal sheet and opens the profile page to change it.
class CalorieGoalBodySummary extends StatelessWidget {
  /// Creates the list for [profile] on [today].
  const new({required this.profile, required this.today, super.key});

  /// The calculator profile with the body data.
  final CalorieCalculatorProfile profile;

  /// The current day, for the age.
  final DateTime today;

  /// Stable key of the link to the profile page.
  static const editInProfileKey = ValueKey<String>(
    'calorie-goal-body-edit-in-profile',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 0;
    final birthDate = profile.birthDate;
    final ageYears = profile.ageAt(today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BodyRow(
          label: l10n.caloriesCalculatorSexLabel,
          value: switch (profile.sex) {
            CalorieCalculatorSex.male => l10n.caloriesCalculatorSexMale,
            CalorieCalculatorSex.female => l10n.caloriesCalculatorSexFemale,
          },
        ),
        _BodyRow(
          label: l10n.caloriesCalculatorHeightLabel,
          value: l10n.caloriesGoalBodyHeightValue(
            number.format(profile.heightCm),
          ),
        ),
        _BodyRow(
          label: l10n.caloriesCalculatorAgeLabel,
          value: birthDate == null
              ? l10n.caloriesGoalBodyAgeValue(ageYears)
              : l10n.caloriesGoalBodyAgeWithBirthday(
                  ageYears,
                  DateFormat.yMd(locale).format(birthDate),
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: editInProfileKey,
            onPressed: () => _openProfile(context),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.caloriesGoalBodyEditInProfile),
          ),
        ),
      ],
    );
  }

  void _openProfile(BuildContext context) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    unawaited(router.push(AppRoutes.homeProfile));
  }
}

class _BodyRow extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
