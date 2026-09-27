import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';

Future<void> _pumpTool(WidgetTester tester, HomeHeaderTool tool) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: tool)),
    ),
  );
}

void main() {
  testWidgets('shows the symbol over the word in capitals', (tester) async {
    await _pumpTool(
      tester,
      HomeHeaderTool(
        symbol: const Icon(Icons.history_rounded),
        label: 'Verlauf',
        onPressed: () {},
      ),
    );

    expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    expect(find.text('VERLAUF'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byIcon(Icons.history_rounded)).dy,
      lessThan(tester.getTopLeft(find.text('VERLAUF')).dy),
    );
  });

  testWidgets('gives the tool a tap area of at least 56 px', (tester) async {
    await _pumpTool(
      tester,
      HomeHeaderTool(
        symbol: const Icon(Icons.more_horiz),
        label: 'Mehr',
        onPressed: () {},
      ),
    );

    final size = tester.getSize(find.byType(HomeHeaderTool));
    expect(size.width, greaterThanOrEqualTo(AppSizes.headerTool));
    expect(size.height, greaterThanOrEqualTo(AppSizes.headerTool));
  });

  testWidgets('announces the word as a button label', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpTool(
      tester,
      HomeHeaderTool(
        symbol: const Text('🏋️'),
        label: 'Training',
        onPressed: () {},
      ),
    );

    expect(
      tester.getSemantics(find.byType(HomeHeaderTool)),
      isSemantics(
        label: 'Training',
        isButton: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('calls back on tap and ignores taps when disabled', (
    tester,
  ) async {
    var taps = 0;
    await _pumpTool(
      tester,
      HomeHeaderTool(
        symbol: const Icon(Icons.more_horiz),
        label: 'Mehr',
        onPressed: () => taps++,
      ),
    );
    await tester.tap(find.byType(HomeHeaderTool));
    expect(taps, 1);

    await _pumpTool(
      tester,
      const HomeHeaderTool(
        symbol: Icon(Icons.more_horiz),
        label: 'Mehr',
        onPressed: null,
      ),
    );
    await tester.tap(find.byType(HomeHeaderTool));
    expect(taps, 1);
  });
}
