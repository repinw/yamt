import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_compact_field_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_control_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('uses row layout above compact breakpoint', (tester) async {
    await tester.pumpWidget(_wrapControlRow(width: 360));

    final firstCard = find.byType(CalorieEntryCompactFieldCard).first;

    expect(
      find.ancestor(of: firstCard, matching: find.byType(Expanded)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: firstCard, matching: find.byType(Row)),
      findsOneWidget,
    );
  });

  testWidgets('uses column layout below compact breakpoint', (tester) async {
    await tester.pumpWidget(_wrapControlRow(width: 300));

    final firstCard = find.byType(CalorieEntryCompactFieldCard).first;

    expect(
      find.ancestor(of: firstCard, matching: find.byType(Expanded)),
      findsNothing,
    );
    expect(
      find.ancestor(of: firstCard, matching: find.byType(Column)),
      findsOneWidget,
    );
  });
}

Widget _wrapControlRow({required double width}) {
  return MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: CalorieEntryControlRow(
            isSaving: false,
            selectedMealType: MealType.breakfast,
            selectedLoggedAt: DateTime(2026, 2, 25, 8),
            onPickLoggedAt: () {},
            onMealTypeChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}
