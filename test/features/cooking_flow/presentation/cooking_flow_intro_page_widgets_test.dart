import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_portion_scaler.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('portion scaler keeps focus while typing multi-digit value', (
    tester,
  ) async {
    var targetPortions = 4;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: CookingFlowIntroPortionScaler(
                originalPortions: 4,
                targetPortions: targetPortions,
                onChanged: (value) {
                  setState(() {
                    targetPortions = value.round();
                  });
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextFormField);
    await tester.tap(field);
    await tester.pump();

    expect(_fieldHasFocus(tester), isTrue);

    await tester.enterText(field, '1');
    await tester.pump();

    expect(_fieldHasFocus(tester), isTrue);

    await tester.enterText(field, '12');
    await tester.pump();

    expect(_fieldHasFocus(tester), isTrue);
    expect(targetPortions, 12);
    expect(find.text('12'), findsOneWidget);
  });
}

bool _fieldHasFocus(WidgetTester tester) {
  final editableText = tester.widget<EditableText>(
    find.byType(EditableText),
  );
  return editableText.focusNode.hasFocus;
}
