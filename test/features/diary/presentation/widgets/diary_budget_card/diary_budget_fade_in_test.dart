import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_fade_in.dart';

void main() {
  double opacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find.ancestor(of: find.text('Ledger'), matching: find.byType(Opacity)),
      )
      .opacity;

  testWidgets('fades in from nothing when it first shows', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: DiaryBudgetFadeIn(order: 1, child: Text('Ledger')),
      ),
    );

    expect(opacity(tester), 0);
    await tester.pump(AppBudgetCard.fadeIn ~/ 2);
    expect(opacity(tester), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
  });

  testWidgets('shows at once when the system asks for less motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DiaryBudgetFadeIn(child: Text('Ledger')),
        ),
      ),
    );

    expect(find.byType(Opacity), findsNothing);
    expect(find.text('Ledger'), findsOneWidget);
  });

  Widget crossFade(String value, {bool disableAnimations = false}) =>
      MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DiaryBudgetCrossFade(value: value, child: Text(value)),
        ),
      );

  testWidgets('cross-fades from the old to the new value', (tester) async {
    await tester.pumpWidget(crossFade('1,200'));
    await tester.pumpWidget(crossFade('900'));
    await tester.pump(AppBudgetCard.fadeIn ~/ 2);

    expect(find.text('1,200'), findsOneWidget);
    expect(find.text('900'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('1,200'), findsNothing);
    expect(find.text('900'), findsOneWidget);
  });

  testWidgets('swaps at once when the system asks for less motion', (
    tester,
  ) async {
    await tester.pumpWidget(crossFade('1,200', disableAnimations: true));
    await tester.pumpWidget(crossFade('900', disableAnimations: true));
    await tester.pump();

    expect(find.text('1,200'), findsNothing);
    expect(find.text('900'), findsOneWidget);
  });
}
