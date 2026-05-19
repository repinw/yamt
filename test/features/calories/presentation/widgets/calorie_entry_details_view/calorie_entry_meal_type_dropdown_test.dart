import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_meal_type_dropdown.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('disables selection and applies disabled text color', (
    tester,
  ) async {
    var changeCount = 0;

    await tester.pumpWidget(
      _wrapDropdown(
        isEnabled: false,
        onMealTypeChanged: (_) => changeCount += 1,
      ),
    );

    final dropdown = tester.widget<AppDropdownButton<MealType>>(
      find.byKey(CalorieEntryDetailKeys.mealSelector),
    );
    final context = tester.element(find.byType(CalorieEntryMealTypeDropdown));
    final disabledColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.45);

    expect(dropdown.onChanged, isNull);
    expect(dropdown.style?.color, disabledColor);

    await tester.tap(find.byKey(CalorieEntryDetailKeys.mealSelector));
    await tester.pumpAndSettle();

    expect(changeCount, 0);
  });
}

Widget _wrapDropdown({
  required bool isEnabled,
  required ValueChanged<MealType> onMealTypeChanged,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 220,
        child: CalorieEntryMealTypeDropdown(
          selectedMealType: MealType.breakfast,
          isEnabled: isEnabled,
          onMealTypeChanged: onMealTypeChanged,
        ),
      ),
    ),
  );
}
