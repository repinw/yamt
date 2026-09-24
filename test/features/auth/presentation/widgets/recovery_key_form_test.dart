import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/key_backup.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/auth_exceptions.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/features/auth/presentation/widgets/recovery_key_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/fake_key_backup.dart';

class _FakeUserDataKeySession extends UserDataKeySession {
  bool startedFresh = false;
  final restoredKeys = <String>[];

  @override
  Future<UserDataKeyState> build() async {
    return const UserDataKeyRecoveryRequired(uid: 'u1');
  }

  @override
  Future<void> restore(String typedRecoveryKey) async {
    restoredKeys.add(typedRecoveryKey);
    throw const InvalidRecoveryKeyException();
  }

  @override
  Future<void> startFresh() async {
    startedFresh = true;
  }
}

void main() {
  late _FakeUserDataKeySession session;
  late FakeKeyBackup keyBackup;

  Future<void> pumpForm(WidgetTester tester) async {
    session = _FakeUserDataKeySession();
    keyBackup = FakeKeyBackup();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDataKeySessionProvider.overrideWith(() => session),
          keyBackupProvider.overrideWithValue(keyBackup),
          firebaseFirestoreProvider.overrideWith(
            (ref) => FakeFirebaseFirestore(),
          ),
        ],
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

  testWidgets('pastes the recovery key from the password manager', (
    tester,
  ) async {
    await pumpForm(tester);
    keyBackup.passwordToPick = 'ABCD-EFGH';

    await tester.tap(find.text('Paste from password manager'));
    await tester.pumpAndSettle();

    expect(session.restoredKeys, <String>['ABCD-EFGH']);
    expect(find.text('ABCD-EFGH'), findsOneWidget);
  });

  testWidgets('does nothing when the user closes the password manager', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text('Paste from password manager'));
    await tester.pumpAndSettle();

    expect(session.restoredKeys, isEmpty);
    expect(find.text('This recovery key is not correct.'), findsNothing);
  });
}
