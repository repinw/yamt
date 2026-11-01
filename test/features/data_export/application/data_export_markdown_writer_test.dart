import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/application/data_export_markdown_writer.dart';

import '../../../helpers/data_export_fixtures.dart';

void main() {
  late DataExportLabels labels;
  late String text;
  late List<String> lines;

  setUpAll(() async {
    labels = await englishLabels();
    text = writeDataExportMarkdown(sampleReport(), labels);
    lines = text.split('\n');
  });

  test('starts with the title and period, then the AI prompt', () {
    expect(lines.first, startsWith('# Nutrition report · '));
    expect(lines.first, contains(labels.date(DateTime(2026, 9, 20))));
    expect(lines.first, contains(labels.date(DateTime(2026, 9, 22))));
    expect(lines[2], '> ${labels.l10n.dataExportAiPrompt}');
  });

  test('holds the sections in order and ends with a newline', () {
    final headers = [
      labels.l10n.dataExportFieldsHeader,
      labels.l10n.dataExportGoalsHeader,
      labels.l10n.dataExportOverviewHeader,
      labels.l10n.dataExportDaysHeader,
    ];
    final positions = [for (final h in headers) text.indexOf('## $h')];

    expect(positions, everyElement(isNonNegative));
    expect([...positions]..sort(), positions);
    expect(text, endsWith('\n'));
  });

  test('lists the goal and the parts of the day', () {
    expect(text, contains('- ${labels.goalLine(sampleReport().goals.single)}'));
    expect(text, contains('- ${labels.mealShares(sampleReport())}'));
  });

  test('says when there is no goal', () {
    final noGoal = writeDataExportMarkdown(
      exportReport([exportDay(DateTime(2026, 9, 20))], withGoal: false),
      labels,
    );

    expect(noGoal, contains(labels.l10n.dataExportNoGoal));
  });

  test('writes one heading per day with eaten and goal numbers', () {
    final headings = lines.where((line) => line.startsWith('### ')).toList();

    expect(headings, hasLength(3));
    expect(
      headings.first,
      '### ${labels.weekdayDate(DateTime(2026, 9, 20))} · Normal day · '
      '400 / 2,000 kcal · P 12/150 g · C 60/200 g · F 8/60 g',
    );
  });

  test('shows a dash for the goal of a pause day', () {
    final pause = lines.singleWhere(
      (line) => line.startsWith('### ') && line.contains('Pause day'),
    );

    expect(pause, contains('0 / – kcal'));
    expect(pause, contains('P 0/– g'));
    expect(pause, contains('C 0/– g'));
    expect(pause, contains('F 0/– g'));
  });

  test('writes weight, TDEE, and meals with their foods', () {
    expect(text, contains('Weight 83.4 kg, trend 83.6 kg'));
    expect(text, contains('TDEE 2,500 kcal'));
    expect(text, contains('**Breakfast · 400 kcal**'));
    expect(
      text,
      contains(
        '- Oats (Farm & <Co>) · 100 g · 400 kcal · P 12 g · C 60 g · F 8 g',
      ),
    );
    expect(
      text,
      contains('- Oats · 100 g · 400 kcal · P 12 g · C 60 g · F 8 g'),
    );
  });

  test('a day without entries says so', () {
    expect(text, contains(labels.l10n.dataExportNoEntries));
  });

  test('the overview averages the logged days and counts day types', () {
    final overview = labels.l10n.dataExportOverviewLine(
      '600',
      '18',
      '90',
      '12',
      '2,500',
    );
    expect(text, contains('- $overview'));
    expect(text, contains('- ${labels.l10n.dataExportDayTypesLine(1, 1, 1)}'));
    expect(text, contains('- Weight: 83.4 kg → 83.4 kg (+0.0 kg)'));
  });
}
