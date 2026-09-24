import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/features/auth/presentation/data_key_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

var _builds = 0;

class _FailingOnceSession extends UserDataKeySession {
  @override
  Future<UserDataKeyState> build() async {
    _builds += 1;
    if (_builds == 1) {
      throw StateError('offline');
    }
    return const UserDataKeyRecoveryRequired(uid: 'u1');
  }
}

void main() {
  setUp(() => _builds = 0);

  testWidgets('retry loads the data key again after a failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDataKeySessionProvider.overrideWith(_FailingOnceSession.new),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DataKeyPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load your data key. Check your connection.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_builds, 2);
    expect(find.text('Restore'), findsOneWidget);
  });
}
