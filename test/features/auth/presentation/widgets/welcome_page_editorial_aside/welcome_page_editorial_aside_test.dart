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
    testWidgets('shows register copy in register mode', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(const EditorialAside(isLoginMode: false)),
      );

      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Create your account and get started.'), findsOneWidget);
      expect(find.text('Yamt'), findsNothing);
    });
  });
}
