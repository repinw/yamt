import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/auth_exceptions.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/features/auth/presentation/widgets/recovery_key_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakeUserDataKeySession extends UserDataKeySession {
  bool startedFresh = false;

  @override
  Future<UserDataKeyState> build() async {
    return const UserDataKeyRecoveryRequired(uid: 'u1');
  }

  @override
  Future<void> restore(String typedRecoveryKey) async {
    throw const InvalidRecoveryKeyException();
  }

  @override
  Future<void> startFresh() async {
    startedFresh = true;
  }
}

void main() {
  late _FakeUserDataKeySession session;

  Future<void> pumpForm(WidgetTester tester) async {
    session = _FakeUserDataKeySession();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userDataKeySessionProvider.overrideWith(() => session)],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RecoveryKeyForm()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an error for a wrong recovery key', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField), 'ABCD-EFGH');
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.text('This recovery key is not correct.'), findsOneWidget);
  });

  testWidgets('starts fresh only after confirmation', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Start fresh without old data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(session.startedFresh, isFalse);

    await tester.tap(find.text('Start fresh without old data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete and start fresh'));
    await tester.pumpAndSettle();
    expect(session.startedFresh, isTrue);
  });
}
