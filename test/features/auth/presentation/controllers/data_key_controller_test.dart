import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/auth_exceptions.dart';
import 'package:yamt/features/auth/presentation/controllers/data_key_controller.dart';

class _FakeUserDataKeySession extends UserDataKeySession {
  final restoredKeys = <String>[];
  bool startedFresh = false;
  bool confirmed = false;

  @override
  Future<UserDataKeyState> build() async {
    return const UserDataKeyRecoveryRequired(uid: 'u1');
  }

  @override
  Future<void> restore(String typedRecoveryKey) async {
    if (typedRecoveryKey != 'right') {
      throw const InvalidRecoveryKeyException();
    }
    restoredKeys.add(typedRecoveryKey);
  }

  @override
  Future<void> startFresh() async {
    startedFresh = true;
  }

  @override
  Future<void> confirmRecoveryKeySaved() async {
    confirmed = true;
  }
}

void main() {
  late _FakeUserDataKeySession session;
  late ProviderContainer container;

  setUp(() {
    session = _FakeUserDataKeySession();
    container = ProviderContainer(
      overrides: [userDataKeySessionProvider.overrideWith(() => session)],
    );
    addTearDown(container.dispose);
  });

  DataKeyController controller() {
    return container.read(dataKeyControllerProvider.notifier);
  }

  test('restore reports success', () async {
    final states = <AsyncValue<void>>[];
    container.listen(
      dataKeyControllerProvider,
      (_, next) => states.add(next),
    );

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
}
