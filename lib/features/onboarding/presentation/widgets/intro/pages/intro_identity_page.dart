import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_input_page_args.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_birth_date_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_fill_page_content.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_gender_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_page_note.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Intro page that asks for gender and birthday.
class IntroIdentityPage extends StatelessWidget {
  /// Creates the identity intro page.
  const new({required this.args, required this.today, super.key});

  /// Chapter styling and the calculator form.
  final IntroInputPageArgs args;

  /// Current day, used for the selectable birthday range.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasSexError = args.showErrors && args.state.sexError != null;

    Widget birthDateCard({required bool expand}) => IntroBirthDateCard(
      birthDate: args.state.birthDate,
      today: today,
      errorText: args.showErrors && args.state.ageError != null
          ? _ageErrorText(args.state.ageError, l10n)
          : null,
      onChanged: args.notifier.updateBirthDate,
      expand: expand,
    );

    return IntroFillPageContent(
      minFillHeight: AppIntroLayout.fillMinHeightTwoPickers,
      kicker: args.kicker,
      accent: args.accent,
      title: l10n.introIdentityTitle,
      subtitle: l10n.introIdentitySubtitle,
      body: ({required fill}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            l10n.caloriesCalculatorSexLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: hasSexError ? colors.error : colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              IntroGenderCard(
                label: l10n.caloriesCalculatorSexFemale,
                icon: Icons.female,
                isSelected: args.state.sex == CalorieCalculatorSex.female,
                hasError: hasSexError,
                onTap: () =>
                    args.notifier.updateSex(CalorieCalculatorSex.female),
              ),
              const SizedBox(width: AppSpacing.md),
              IntroGenderCard(
                label: l10n.caloriesCalculatorSexMale,
                icon: Icons.male,
                isSelected: args.state.sex == CalorieCalculatorSex.male,
                hasError: hasSexError,
                onTap: () => args.notifier.updateSex(CalorieCalculatorSex.male),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (fill)
            Expanded(child: birthDateCard(expand: true))
          else
            birthDateCard(expand: false),
        ],
      ),
      footer: IntroPageNote(
        icon: Icons.lock_outline,
        message: l10n.introIdentityPrivacyNote,
      ),
    );
  }

  String _ageErrorText(
    CalorieCalculatorFieldError? error,
    AppLocalizations l10n,
  ) {
    return switch (error) {
      CalorieCalculatorFieldError.invalid => l10n.caloriesCalculatorAgeInvalid,
      _ => l10n.introBirthDateEmpty,
    };
  }
}
