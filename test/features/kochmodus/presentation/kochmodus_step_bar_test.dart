import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('three tabs at double text size fit 360 dp without overflow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: KochmodusStepBar(
            current: KochmodusStep.cook,
            locked: const {KochmodusStep.portion},
            onSelect: (_) {},
            onBack: () {},
            onDiscard: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    for (final step in KochmodusStep.values) {
      final tab = find.byKey(KochmodusStepBar.tabKey(step));
      expect(tab, findsOneWidget);
      final label = find.descendant(of: tab, matching: find.byType(Text));
      expect(label, findsOneWidget);
      final box = tester.getRect(label);
      final tabBox = tester.getRect(tab);
      // The label is painted inside its tab, not cut off.
      expect(box.left, greaterThanOrEqualTo(tabBox.left));
      expect(box.right, lessThanOrEqualTo(tabBox.right + 0.5));
    }
  });
}
