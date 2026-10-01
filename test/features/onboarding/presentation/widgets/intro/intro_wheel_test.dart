import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_wheel.dart';

const _wheelKey = Key('wheel');

/// Drag distance that moves a wheel by one item.
const _oneItem = 34.0;

/// Hosts an [IntroWheel] whose index the test can change from outside, like a
/// form controller does when another field changes.
class _WheelHost extends StatefulWidget {
  const new({required this.reported});

  final List<int> reported;

  @override
  State<_WheelHost> createState() => _WheelHostState();
}

class _WheelHostState extends State<_WheelHost> {
  int _selectedIndex = 30;

  void selectFromOutside(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return IntroWheel(
      key: _wheelKey,
      itemCount: 31,
      selectedIndex: _selectedIndex,
      labelBuilder: (index) => '${index + 1}',
      // Writes state like the form controller; during a build this throws.
      onSelected: (index) {
        widget.reported.add(index);
        setState(() => _selectedIndex = index);
      },
    );
  }
}

Future<List<int>> _pumpHost(WidgetTester tester) async {
  final reported = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: _WheelHost(reported: reported)),
    ),
  );
  await tester.pumpAndSettle();
  return reported;
}

void main() {
  testWidgets('does not report an index set from outside', (tester) async {
    final reported = await _pumpHost(tester);

    tester
        .state<_WheelHostState>(find.byType(_WheelHost))
        .selectFromOutside(27);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(reported, isEmpty);
    expect(find.text('28'), findsOneWidget);
  });

  testWidgets('reports the index the user scrolls to', (tester) async {
    final reported = await _pumpHost(tester);

    await tester.drag(find.byKey(_wheelKey), const Offset(0, _oneItem));
    await tester.pumpAndSettle();

    expect(reported.last, 29);
  });

  testWidgets('reports user scrolls after an index set from outside', (
    tester,
  ) async {
    final reported = await _pumpHost(tester);

    tester
        .state<_WheelHostState>(find.byType(_WheelHost))
        .selectFromOutside(27);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(_wheelKey), const Offset(0, _oneItem));
    await tester.pumpAndSettle();

    expect(reported.last, 26);
  });
}
