import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/app_color_picker.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('a screen reader steps hue and saturation of the wheel', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changes = <Color>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AppColorPicker(
            color: const HSVColor.fromAHSV(1, 100, 0.5, 1).toColor(),
            onChanged: changes.add,
            wheelSize: 200,
            besideWheel: const SizedBox(),
          ),
        ),
      ),
    );

    final hue = find.bySemanticsLabel('Hue');
    final saturation = find.bySemanticsLabel('Saturation');
    expect(tester.getSemantics(hue).value, '100°');
    expect(tester.getSemantics(saturation).value, '50%');

    tester.semantics.performAction(
      find.semantics.byLabel('Hue'),
      SemanticsAction.increase,
    );
    await tester.pump();
    expect(HSVColor.fromColor(changes.last).hue, closeTo(115, 0.5));

    tester.semantics.performAction(
      find.semantics.byLabel('Saturation'),
      SemanticsAction.decrease,
    );
    await tester.pump();
    expect(HSVColor.fromColor(changes.last).saturation, closeTo(0.4, 0.01));
    expect(tester.getSemantics(saturation).value, '40%');
    handle.dispose();
  });
}
