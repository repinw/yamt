import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';

void main() {
  test('the welcome page is the cover without a chapter number', () {
    expect(CalorieIntroPage.welcome.chapterNumber, isNull);
  });

  test('chapters are numbered from one', () {
    expect(CalorieIntroPage.calorieModel.chapterNumber, 1);
    expect(CalorieIntroPage.summary.chapterNumber, 13);
    expect(CalorieIntroPage.chapterCount, 13);
  });

  test('every page but the last knows its successor', () {
    expect(CalorieIntroPage.welcome.next, CalorieIntroPage.calorieModel);
    expect(CalorieIntroPage.pace.next, CalorieIntroPage.summary);
    expect(CalorieIntroPage.summary.next, isNull);
  });
}
