import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/presentation/widgets/welcome_page_editorial_aside/welcome_page_editorial_aside.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 500, height: 520, child: child)),
  );
}

void main() {
  group('EditorialAside', () {
    testWidgets('shows the brand copy', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const EditorialAside()));

      expect(find.text('Yamt'), findsOneWidget);
      expect(find.text('Yet Another Meal Tracker'), findsOneWidget);
    });
  });
}
