import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/auth_exceptions.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/features/auth/presentation/controllers/data_key_controller.dart';

/// Records the calls of [_FakeUserDataKeySession].
class _SessionCalls {
  final restoredKeys = <String>[];
  bool startedFresh = false;
  bool confirmed = false;

  /// What the password manager does: saves, cancels (`false`), or throws
  /// (`null`).
  bool? passwordManagerSaves = true;
  final passwordManagerAccounts = <String>[];
}

class _FakeUserDataKeySession extends UserDataKeySession {
  new(this._calls);

  final _SessionCalls _calls;

  @override
  Future<UserDataKeyState> build() async {
    return const UserDataKeyRecoveryRequired(uid: 'u1');
  }

  @override
  Future<void> restore(String typedRecoveryKey) async {
    if (typedRecoveryKey != 'right') {
      throw const InvalidRecoveryKeyException();
    }
    _calls.restoredKeys.add(typedRecoveryKey);
  }

  @override
  Future<void> startFresh() async {
    _calls.startedFresh = true;
  }

  @override
  Future<void> confirmRecoveryKeySaved() async {
    _calls.confirmed = true;
  }

  @override
  Future<bool> saveRecoveryKeyToPasswordManager({
    required String accountName,
  }) async {
    _calls.passwordManagerAccounts.add(accountName);
    final saves = _calls.passwordManagerSaves;
    if (saves == null) {
      throw StateError('Password manager failed.');
    }
    return saves;
  }
}

void main() {
  late _SessionCalls session;
  late ProviderContainer container;

  setUp(() {
    session = _SessionCalls();
    container = ProviderContainer(
      overrides: [
        userDataKeySessionProvider.overrideWith(
          () => _FakeUserDataKeySession(session),
        ),
        authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);
  });

  DataKeyController controller() {
    return container.read(dataKeyControllerProvider.notifier);
  }

  test('restore reports success', () async {
    final states = <AsyncValue<void>>[];
    container.listen(dataKeyControllerProvider, (_, next) => states.add(next));

    final restored = await controller().restore('right');

    expect(restored, isTrue);
    expect(session.restoredKeys, <String>['right']);
    expect(states.first, isA<AsyncLoading<void>>());
    expect(states.last, const AsyncData<void>(null));
  });

  test('restore exposes a wrong recovery key as error', () async {
    final subscription = container.listen(dataKeyControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    final restored = await controller().restore('wrong');

    expect(restored, isFalse);
    expect(
      container.read(dataKeyControllerProvider).error,
      isA<InvalidRecoveryKeyException>(),
    );
  });

  test('startFresh and confirm call the session', () async {
    final subscription = container.listen(dataKeyControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    expect(await controller().startFresh(), isTrue);
    expect(await controller().confirmRecoveryKeySaved(), isTrue);

    expect(session.startedFresh, isTrue);
    expect(session.confirmed, isTrue);
  });

  test(
    'saving in the password manager reports saved, canceled, or failed',
    () async {
      final subscription = container.listen(
        dataKeyControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      expect(
        await controller().saveRecoveryKeyToPasswordManager(),
        RecoveryKeySaveResult.saved,
      );
      session.passwordManagerSaves = false;
      expect(
        await controller().saveRecoveryKeyToPasswordManager(),
        RecoveryKeySaveResult.canceled,
      );
      session.passwordManagerSaves = null;
      expect(
        await controller().saveRecoveryKeyToPasswordManager(),
        RecoveryKeySaveResult.failed,
      );
      expect(session.passwordManagerAccounts, everyElement('YAMT'));
    },
  );
}
