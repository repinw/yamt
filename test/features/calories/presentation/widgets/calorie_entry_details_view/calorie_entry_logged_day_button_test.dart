import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_logged_day_button.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('disables tap and applies disabled text color', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _wrapLoggedDayButton(
        isEnabled: false,
        onPressed: () => tapCount += 1,
      ),
    );

    final inkWell = tester.widget<AppInkWell>(
      find.byKey(CalorieEntryDetailKeys.loggedDayButton),
    );
    final context = tester.element(find.byType(CalorieEntryLoggedDayButton));
    final disabledColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.45);
    final label = tester.widget<Text>(
      find
          .descendant(
            of: find.byKey(CalorieEntryDetailKeys.loggedDayButton),
            matching: find.byType(Text),
          )
          .first,
    );

    expect(inkWell.onTap, isNull);
    expect(label.style?.color, disabledColor);

    await tester.tap(find.byKey(CalorieEntryDetailKeys.loggedDayButton));
    await tester.pump();

    expect(tapCount, 0);
  });
}

Widget _wrapLoggedDayButton({
  required bool isEnabled,
  required VoidCallback onPressed,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return CalorieEntryLoggedDayButton(
            loggedAt: DateTime(2026, 2, 25, 8),
            isEnabled: isEnabled,
            onPressed: onPressed,
            material: MaterialLocalizations.of(context),
          );
        },
      ),
    ),
  );
}
