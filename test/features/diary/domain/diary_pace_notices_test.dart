import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';

void main() {
  group('diaryPaceMacro', () {
    const targets = (protein: 100.0, carbs: 200.0, fat: 50.0);

    test('is the macro with the largest share of its target left', () {
      expect(
        diaryPaceMacro(
          eaten: (protein: 50, carbs: 190, fat: 40),
          targets: targets,
        ),
        DiaryPaceMacro.protein,
      );
      expect(
        diaryPaceMacro(
          eaten: (protein: 90, carbs: 40, fat: 40),
          targets: targets,
        ),
        DiaryPaceMacro.carbs,
      );
      expect(
        diaryPaceMacro(
          eaten: (protein: 90, carbs: 190, fat: 10),
          targets: targets,
        ),
        DiaryPaceMacro.fat,
      );
    });

    test('is null when no macro has anything left', () {
      expect(
        diaryPaceMacro(
          eaten: (protein: 100, carbs: 250, fat: 60),
          targets: targets,
        ),
        isNull,
      );
    });

    test('ignores a macro without a target', () {
      expect(
        diaryPaceMacro(
          eaten: (protein: 0, carbs: 0, fat: 0),
          targets: (protein: 0, carbs: 0, fat: 50),
        ),
        DiaryPaceMacro.fat,
      );
      expect(
        diaryPaceMacro(
          eaten: (protein: 0, carbs: 0, fat: 0),
          targets: (protein: 0, carbs: 0, fat: 0),
        ),
        isNull,
      );
    });
  });
}
