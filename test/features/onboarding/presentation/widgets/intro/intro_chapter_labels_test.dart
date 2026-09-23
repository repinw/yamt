import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/'
    'intro_chapter_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('pads the chapter counter to two digits', () {
    expect(CalorieIntroPage.inputQuality.counter(l10n), '02 / 13');
  });

  test('names the chapter in the kicker', () {
    expect(CalorieIntroPage.body.kicker(l10n), 'Chapter 8 · Body measurements');
  });

  test('labels the next action with the following chapter', () {
    expect(CalorieIntroPage.target.nextActionLabel(l10n), 'Next: Pace');
    expect(CalorieIntroPage.summary.nextActionLabel(l10n), isNull);
  });

  test('groups pages into four sections', () {
    expect(CalorieIntroPage.trend.categoryName(l10n), 'How YAMT calculates');
    expect(CalorieIntroPage.extras.categoryName(l10n), 'Beyond calories');
    expect(CalorieIntroPage.identity.categoryName(l10n), 'Your profile');
    expect(CalorieIntroPage.summary.categoryName(l10n), 'Your start');
  });
}
