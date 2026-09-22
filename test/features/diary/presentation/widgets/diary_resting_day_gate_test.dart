import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_placeholder.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_resting_day_gate.dart';

void main() {
  testWidgets('shows the day only next to the resting page', (tester) async {
    final restingPage = ValueNotifier<int>(0);
    addTearDown(restingPage.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              for (var index = 0; index < 3; index++)
                Expanded(
                  child: DiaryRestingDayGate(
                    index: index,
                    restingPage: restingPage,
                    child: Text('Day $index'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Day 0'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Day 2'), findsNothing);
    expect(find.byType(DiaryDayPlaceholder), findsOneWidget);

    restingPage.value = 2;
    await tester.pump();

    expect(find.text('Day 0'), findsNothing);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Day 2'), findsOneWidget);
  });
}
