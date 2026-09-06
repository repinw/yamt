import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_transition.dart';

void main() {
  late double value;
  late double highlight;

  Widget transition({
    double current = 75,
    double? previous = 50,
    DateTime? startedAt,
    bool reduced = false,
  }) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: DiaryMacroTransition(
      current: current,
      previous: previous,
      startedAt: startedAt,
      builder: (context, intake, opacity) {
        value = intake;
        highlight = opacity;
        return const SizedBox();
      },
    ),
  );

  testWidgets('confirmed additions reach their final value within 700 ms', (
    tester,
  ) async {
    await tester.pumpWidget(transition(startedAt: DateTime.now()));
    final initial = value;
    expect(initial, greaterThanOrEqualTo(50));
    expect(initial, lessThan(75));
    await tester.pump(const Duration(milliseconds: 350));
    expect(value, greaterThan(initial));
    expect(value, lessThan(75));
    expect(highlight, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 350));
    expect(value, 75);
    expect(highlight, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 700));
    expect(highlight, 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('ordinary updates render immediately without an intake event', (
    tester,
  ) async {
    await tester.pumpWidget(transition());
    expect(value, 75);
    expect(highlight, 0);
    await tester.pumpWidget(transition(current: 90));
    expect(value, 90);
    expect(highlight, 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('rebuilds do not restart the same addition', (tester) async {
    final start = DateTime.now();
    await tester.pumpWidget(transition(startedAt: start));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpWidget(transition(startedAt: start));
    expect(value, 75);
    await tester.pump(const Duration(milliseconds: 700));
    expect(highlight, 0);
  });

  testWidgets('completed additions do not replay after remounting', (
    tester,
  ) async {
    await tester.pumpWidget(
      transition(
        startedAt: DateTime.now().subtract(const Duration(seconds: 2)),
      ),
    );
    expect(value, 75);
    expect(highlight, 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('late mounts join the shared transition at its current time', (
    tester,
  ) async {
    await tester.pumpWidget(
      transition(
        startedAt: DateTime.now().subtract(const Duration(milliseconds: 350)),
      ),
    );
    expect(value, greaterThan(70));
    expect(value, lessThan(75));
    await tester.pump(const Duration(milliseconds: 350));
    expect(value, 75);
  });

  testWidgets('reduced motion shows end values and no highlight immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      transition(startedAt: DateTime.now(), reduced: true),
    );
    expect(value, 75);
    expect(highlight, 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('missing previous intake cannot animate an invented baseline', (
    tester,
  ) async {
    await tester.pumpWidget(
      transition(previous: null, startedAt: DateTime.now()),
    );
    expect(value, 75);
    expect(highlight, 0);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
