import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/macro_reference_weight.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_chapter_accent.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_input_page_args.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_chapter_theme.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/'
    'intro_chapter_labels.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/pages/'
    'intro_activity_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/pages/'
    'intro_body_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/pages/'
    'intro_identity_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/pages/'
    'intro_pace_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/pages/'
    'intro_sport_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/pages/'
    'intro_story_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/pages/'
    'intro_summary_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/pages/'
    'intro_target_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/pages/'
    'intro_welcome_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Builds the intro pages in the order of [CalorieIntroPage].
List<Widget> buildCalorieIntroPages({
  required BuildContext context,
  required AppLocalizations l10n,
  required CalorieGoalCalculatorFormState formState,
  required CalorieGoalCalculatorFormController formNotifier,
  required bool showErrors,
  required DateTime today,
  required DateTime startDate,
  required ValueChanged<DateTime> onStartDateChanged,
  required VoidCallback onStart,
  required VoidCallback onLogin,
}) {
  Color accentOf(CalorieIntroPage page) => page.accent.resolve(context);
  String kickerOf(CalorieIntroPage page) => page.kicker(l10n);

  IntroInputPageArgs argsFor(CalorieIntroPage page) => IntroInputPageArgs(
    kicker: kickerOf(page),
    accent: accentOf(page),
    state: formState,
    notifier: formNotifier,
    showErrors: showErrors,
  );

  Widget story(
    CalorieIntroPage page, {
    required IconData icon,
    required String title,
    required String body,
    String? titleHighlight,
    String? footnote,
  }) {
    return IntroStoryPage(
      icon: icon,
      kicker: kickerOf(page),
      title: title,
      titleHighlight: titleHighlight,
      body: body,
      accent: accentOf(page),
      footnote: footnote,
    );
  }

  Widget pageFor(CalorieIntroPage page) => switch (page) {
    CalorieIntroPage.welcome => IntroWelcomePage(
      onStart: onStart,
      onLogin: onLogin,
    ),
    CalorieIntroPage.calorieModel => story(
      page,
      icon: Icons.balance,
      title: l10n.introCalorieModelTitle,
      titleHighlight: l10n.introCalorieModelHighlight,
      body: l10n.introCalorieModelBody,
      footnote: l10n.introCalorieModelNote,
    ),
    CalorieIntroPage.inputQuality => story(
      page,
      icon: Icons.calculate_outlined,
      title: l10n.introInputQualityTitle,
      titleHighlight: l10n.introInputQualityHighlight,
      body: l10n.introInputQualityBody,
      footnote: l10n.introInputQualityNote,
    ),
    CalorieIntroPage.followTarget => story(
      page,
      icon: Icons.auto_mode,
      title: l10n.introFollowTargetTitle,
      titleHighlight: l10n.introFollowTargetHighlight,
      body: l10n.introFollowTargetBody,
      footnote: l10n.introFollowTargetNote,
    ),
    CalorieIntroPage.trend => story(
      page,
      icon: Icons.show_chart,
      title: l10n.introTrendTitle,
      titleHighlight: l10n.introTrendHighlight,
      body: l10n.introTrendBody,
      footnote: l10n.introTrendNote,
    ),
    CalorieIntroPage.goalDirection => story(
      page,
      icon: Icons.swap_vert,
      title: l10n.introGoalDirectionTitle,
      titleHighlight: l10n.introGoalDirectionHighlight,
      body: l10n.introGoalDirectionBody,
      footnote: l10n.introGoalDirectionNote,
    ),
    CalorieIntroPage.extras => story(
      page,
      icon: Icons.kitchen_outlined,
      title: l10n.introExtrasTitle,
      titleHighlight: l10n.introExtrasHighlight,
      body: l10n.introExtrasBody,
      footnote: l10n.introExtrasNote,
    ),
    CalorieIntroPage.identity => IntroIdentityPage(
      args: argsFor(page),
      today: today,
    ),
    CalorieIntroPage.body => IntroBodyPage(args: argsFor(page)),
    CalorieIntroPage.target => IntroTargetPage(args: argsFor(page)),
    CalorieIntroPage.pace => IntroPacePage(args: argsFor(page), today: today),
    CalorieIntroPage.activity => IntroActivityPage(args: argsFor(page)),
    CalorieIntroPage.sport => IntroSportPage(args: argsFor(page)),
    CalorieIntroPage.summary => IntroSummaryPage(
      kicker: kickerOf(page),
      accent: accentOf(page),
      calculation: formState.calculation,
      trainingWeekdays: formState.trainingWeekdays,
      trainingDayKcalOffset: formState.trainingDayKcalOffset,
      today: today,
      startDate: startDate,
      onStartDateChanged: onStartDateChanged,
      adjustedMacroWeightKg: switch (formState.profile) {
        final profile? => macroAdjustedWeightKg(
          weightKg: profile.weightKg,
          heightCm: profile.heightCm,
        ),
        null => null,
      },
    ),
  };

  return [
    for (final page in CalorieIntroPage.values)
      IntroChapterTheme(accent: accentOf(page), child: pageFor(page)),
  ];
}
