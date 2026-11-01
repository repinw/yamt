import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/application/data_export_xlsx_writer.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';

import '../../../helpers/data_export_fixtures.dart';

void main() {
  late DataExportLabels labels;
  late Archive archive;

  String sheet(int number) =>
      utf8.decode(archive.findFile('xl/worksheets/sheet$number.xml')!.content);

  setUpAll(() async {
    labels = await englishLabels();
    archive = ZipDecoder().decodeBytes(
      writeDataExportXlsx(sampleReport(), labels),
    );
  });

  test('makes a workbook with the sheets days, meals, foods, and goals', () {
    final workbook = utf8.decode(archive.findFile('xl/workbook.xml')!.content);

    for (final (index, name) in ['Days', 'Meals', 'Foods', 'Goals'].indexed) {
      expect(workbook, contains('<sheet name="$name" sheetId="${index + 1}"'));
    }
    expect(archive.findFile('xl/worksheets/sheet4.xml'), isNotNull);
    expect(archive.findFile('xl/worksheets/sheet5.xml'), isNull);
  });

  test('days sheet has one row per day below its header', () {
    final days = sheet(1);

    // Header and three days.
    expect('<row '.allMatches(days), hasLength(4));
    // Eaten kcal and weight stay numbers.
    expect(days, contains('<c r="D2"><v>400.0</v></c>'));
    expect(days, contains('<c r="K2"><v>83.4</v></c>'));
    expect(days, contains('<c r="M2"><v>2500.0</v></c>'));
  });

  test('a pause day has no goal cells', () {
    final days = sheet(1);

    // Row 4 is the pause day: day type text, eaten kcal, but no goals.
    expect(days, contains('<c r="B4" t="inlineStr">'));
    expect(days, contains('<c r="D4"><v>0.0</v></c>'));
    for (final column in ['C', 'E', 'G', 'I']) {
      expect(days, isNot(contains('r="${column}4"')));
    }
    // A day with a goal has them.
    expect(days, contains('<c r="C2"><v>2000.0</v></c>'));
  });

  test('meals sheet has a row per meal with its part of the day', () {
    final meals = sheet(2);

    // Header, breakfast, lunch, dinner.
    expect('<row '.allMatches(meals), hasLength(4));
    // 2000 kcal goal, breakfast part 25 percent.
    expect(meals, contains('<c r="C2"><v>500</v></c>'));
  });

  test('meals sheet has no meal goal on a pause day', () {
    // The pause day keeps the normal goal kcal, as goalKcalForDay does.
    final report = exportReport([
      exportDay(
        DateTime(2026, 9, 22),
        type: DiaryDayType.pause,
        meals: [
          DataExportMeal(mealType: MealType.breakfast, foods: [oatEntry()]),
        ],
      ),
    ]);
    final meals = utf8.decode(
      ZipDecoder()
          .decodeBytes(writeDataExportXlsx(report, labels))
          .findFile('xl/worksheets/sheet2.xml')!
          .content,
    );

    expect(meals, isNot(contains('r="C2"')));
    expect(meals, contains('<c r="D2"><v>400.0</v></c>'));
  });

  test('foods sheet escapes the brand', () {
    final foods = sheet(3);

    expect('<row '.allMatches(foods), hasLength(4));
    expect(foods, contains('Farm &amp; &lt;Co&gt;'));
    expect(foods, isNot(contains('<Co>')));
    expect(foods, contains('<v>100.0</v>'));
  });

  test('goals sheet lists the goal and the parts of the day', () {
    final goals = sheet(4);

    expect(goals, contains('<c r="A2"><v>1</v></c>'));
    expect(goals, contains('running'));
    // Header, one goal, an empty row, the share header, four meals.
    expect('<row '.allMatches(goals), hasLength(8));
    expect(goals, contains('<v>25</v>'));
    expect(goals, contains('<v>10</v>'));
  });
}
