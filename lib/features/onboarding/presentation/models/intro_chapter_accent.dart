import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/intro_accent_colors.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';

/// Accent a page uses for its kicker, highlights, and progress segment.
enum IntroChapterAccent {
  /// Warm accent.
  amber,

  /// Cool accent.
  cyan,

  /// Green accent.
  emerald,

  /// Purple accent.
  violet,

  /// Blue accent.
  sky,

  /// Red accent.
  rose;

  /// The accent that pairs with this one in the chapter scenery.
  IntroChapterAccent get counterpart => switch (this) {
    IntroChapterAccent.amber => IntroChapterAccent.rose,
    IntroChapterAccent.cyan => IntroChapterAccent.rose,
    IntroChapterAccent.emerald => IntroChapterAccent.cyan,
    IntroChapterAccent.violet => IntroChapterAccent.sky,
    IntroChapterAccent.sky => IntroChapterAccent.violet,
    IntroChapterAccent.rose => IntroChapterAccent.amber,
  };

  /// Resolves this accent against the active theme.
  Color resolve(BuildContext context) {
    final accents = introAccentsOf(context);
    return switch (this) {
      IntroChapterAccent.amber => accents.amber,
      IntroChapterAccent.cyan => accents.cyan,
      IntroChapterAccent.emerald => accents.emerald,
      IntroChapterAccent.violet => accents.violet,
      IntroChapterAccent.sky => accents.sky,
      IntroChapterAccent.rose => accents.rose,
    };
  }
}

/// The accent of every intro page.
extension CalorieIntroPageAccent on CalorieIntroPage {
  /// Accent color role of this page.
  IntroChapterAccent get accent => switch (this) {
    CalorieIntroPage.welcome => IntroChapterAccent.emerald,
    CalorieIntroPage.calorieModel => IntroChapterAccent.amber,
    CalorieIntroPage.inputQuality => IntroChapterAccent.cyan,
    CalorieIntroPage.followTarget => IntroChapterAccent.emerald,
    CalorieIntroPage.goalDirection => IntroChapterAccent.rose,
    CalorieIntroPage.trend => IntroChapterAccent.sky,
    CalorieIntroPage.extras => IntroChapterAccent.amber,
    CalorieIntroPage.identity => IntroChapterAccent.violet,
    CalorieIntroPage.body => IntroChapterAccent.sky,
    CalorieIntroPage.target => IntroChapterAccent.emerald,
    CalorieIntroPage.activity => IntroChapterAccent.amber,
    CalorieIntroPage.sport => IntroChapterAccent.rose,
    CalorieIntroPage.pace => IntroChapterAccent.cyan,
    CalorieIntroPage.summary => IntroChapterAccent.emerald,
  };
}
