import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/key_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('de.yamt.app/key_backup');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'load' => 'ABCD',
            'saveToPasswordManager' => true,
            'loadFromPasswordManager' => 'EFGH',
            _ => null,
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
  });

  test('AndroidKeyBackup passes names and values to the channel', () async {
    const backup = AndroidKeyBackup();

    await backup.save('recovery_key_u1', 'ABCD');
    final loaded = await backup.load('recovery_key_u1');
    await backup.delete('recovery_key_u1');
    final saved = await backup.saveToPasswordManager(
      id: 'jane@example.com',
      password: 'ABCD',
    );
    final picked = await backup.loadFromPasswordManager();

    expect(loaded, 'ABCD');
    expect(saved, isTrue);
    expect(picked, 'EFGH');
    expect(calls.map((call) => call.method), <String>[
      'save',
      'load',
      'delete',
      'saveToPasswordManager',
      'loadFromPasswordManager',
    ]);
    expect(calls.first.arguments, <String, String>{
      'key': 'recovery_key_u1',
      'value': 'ABCD',
    });
    expect(calls[3].arguments, <String, String>{
      'id': 'jane@example.com',
      'password': 'ABCD',
    });
  });

  test('UnavailableKeyBackup stores nothing and has no password manager', () {
    const backup = UnavailableKeyBackup();

    expect(backup.canSaveToPasswordManager, isFalse);
    expect(backup.load('recovery_key_u1'), completion(isNull));
    expect(
      () => backup.saveToPasswordManager(id: 'a', password: 'b'),
      throwsUnsupportedError,
    );
  });
}
