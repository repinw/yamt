import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';

const _lineKey = ValueKey<String>('line');
const _width = 300.0;

Future<void> _pump(
  WidgetTester tester, {
  double? pace,
  double? target = 2000,
  double? scaleKcal,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        // Align gives the line a loose width, which the scaffold would
        // otherwise force to the whole screen.
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: _width,
            child: DiaryBudgetLine(
              key: _lineKey,
              eaten: 800,
              target: target,
              scaleKcal: scaleKcal,
              pace: pace,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Where the pace marker's center sits, from the left edge of the line.
double _markerCenter(WidgetTester tester) {
  final line = tester.getRect(find.byKey(_lineKey));
  return tester.getCenter(find.byKey(DiaryBudgetLine.paceKey)).dx - line.left;
}

void main() {
  testWidgets('draws no marker without a pace', (tester) async {
    await _pump(tester);

    expect(find.byKey(DiaryBudgetLine.paceKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('draws one marker with a pace', (tester) async {
    await _pump(tester, pace: 1000);

    expect(find.byKey(DiaryBudgetLine.paceKey), findsOneWidget);
    expect(
      tester.getSize(find.byKey(DiaryBudgetLine.paceKey)).width,
      AppBudgetCard.paceMarker,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('puts the marker where the pace is on the line, which reaches '
      '120 % of the target', (tester) async {
    // 300 wide for 120 % of 2,000 kcal: 1,000 kcal sits at 125.
    await _pump(tester, pace: 1000);
    expect(_markerCenter(tester), closeTo(125, 1e-6));

    // The target itself sits at 250, where the goal marker is.
    await _pump(tester, pace: 2000);
    expect(_markerCenter(tester), closeTo(250, 1e-6));

    await _pump(tester, pace: 500);
    expect(_markerCenter(tester), closeTo(62.5, 1e-6));
  });

  testWidgets('moves the marker when the pace moves on', (tester) async {
    await _pump(tester, pace: 500);
    final before = _markerCenter(tester);

    await _pump(tester, pace: 1000);

    expect(_markerCenter(tester), greaterThan(before));
    expect(_markerCenter(tester), closeTo(125, 1e-6));
  });

  testWidgets('keeps the marker whole at the start of the line', (
    tester,
  ) async {
    await _pump(tester, pace: 0);

    final line = tester.getRect(find.byKey(_lineKey));
    final marker = tester.getRect(find.byKey(DiaryBudgetLine.paceKey));
    expect(marker.left, line.left);
    expect(marker.width, AppBudgetCard.paceMarker);
  });

  testWidgets('keeps the marker whole at the end of the line, also for a '
      'pace past what the line shows', (tester) async {
    for (final pace in [2400.0, 5000.0]) {
      await _pump(tester, pace: pace);

      final line = tester.getRect(find.byKey(_lineKey));
      final marker = tester.getRect(find.byKey(DiaryBudgetLine.paceKey));
      expect(marker.right, closeTo(line.right, 1e-6), reason: '$pace');
      expect(marker.width, AppBudgetCard.paceMarker);
    }
  });

  testWidgets('sits above and through the bar, inside the line', (
    tester,
  ) async {
    await _pump(tester, pace: 1000);

    final line = tester.getRect(find.byKey(_lineKey));
    final marker = tester.getRect(find.byKey(DiaryBudgetLine.paceKey));
    expect(marker.top, line.top);
    // The stroke ends at the bar's lower edge, which is as far from the
    // bottom of the line as the bar's upper edge is from its top.
    expect(
      line.bottom - marker.bottom,
      closeTo((AppBudgetCard.line - AppBudgetCard.lineBar) / 2, 1e-6),
    );
  });

  testWidgets('draws a marker on a line without a target, against the scale '
      'it is given', (tester) async {
    await _pump(tester, target: null, scaleKcal: 2000, pace: 1000);

    expect(_markerCenter(tester), closeTo(125, 1e-6));
    expect(tester.takeException(), isNull);
  });
}
