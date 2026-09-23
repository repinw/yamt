import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Width the chapter counter pads its numbers to.
const _counterDigits = 2;

/// Resolves the localized chapter labels of an intro page.
extension CalorieIntroPageLabels on CalorieIntroPage {
  /// Short chapter name, for example `Target weight`.
  String chapterName(AppLocalizations l10n) => switch (this) {
    CalorieIntroPage.welcome => l10n.introChapterEnergyBalance,
    CalorieIntroPage.calorieModel => l10n.introChapterEnergyBalance,
    CalorieIntroPage.inputQuality => l10n.introChapterStartValue,
    CalorieIntroPage.followTarget => l10n.introChapterCorrection,
    CalorieIntroPage.goalDirection => l10n.introChapterGoalDirection,
    CalorieIntroPage.trend => l10n.introChapterTrend,
    CalorieIntroPage.extras => l10n.introChapterKitchen,
    CalorieIntroPage.identity => l10n.introChapterProfile,
    CalorieIntroPage.body => l10n.introChapterBody,
    CalorieIntroPage.target => l10n.introChapterTargetWeight,
    CalorieIntroPage.activity => l10n.introChapterActivity,
    CalorieIntroPage.sport => l10n.introChapterTraining,
    CalorieIntroPage.pace => l10n.introChapterPace,
    CalorieIntroPage.summary => l10n.introChapterResult,
  };

  /// Section this page belongs to.
  String categoryName(AppLocalizations l10n) {
    if (this == CalorieIntroPage.summary) {
      return l10n.introCategoryYourStart;
    }
    if (this == CalorieIntroPage.extras) {
      return l10n.introCategoryBeyondCalories;
    }
    return index < CalorieIntroPage.extras.index
        ? l10n.introCategoryHowItWorks
        : l10n.introCategoryYourProfile;
  }

  /// Kicker shown above the headline, for example `Chapter 3 · The trend`.
  String kicker(AppLocalizations l10n) {
    return l10n.introChapterKicker(chapterNumber ?? 0, chapterName(l10n));
  }

  /// Counter shown in the chapter chrome, for example `03 / 13`.
  String counter(AppLocalizations l10n) {
    return l10n.introChapterCounter(
      '${chapterNumber ?? 0}'.padLeft(_counterDigits, '0'),
      '${CalorieIntroPage.chapterCount}'.padLeft(_counterDigits, '0'),
    );
  }

  /// Label of the shared next action, naming the chapter it leads to.
  String? nextActionLabel(AppLocalizations l10n) {
    final target = next;
    if (target == null) {
      return null;
    }
    return l10n.introNextChapterAction(target.chapterName(l10n));
  }
}
