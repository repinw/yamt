import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('reads and removes async preference values', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme': 'dark',
      'launch_count': 3,
    });
    final store = SharedPreferencesStore();

    expect(await store.getString('theme'), 'dark');
    expect(await store.getInt('launch_count'), 3);
    expect(await store.remove('theme'), isTrue);

    expect(await store.getString('theme'), isNull);
    expect(await store.getInt('launch_count'), 3);
  });

  test('uses injected preferences for sync reads and writes', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesStore(preferences: preferences);

    expect(store.getStringSync('theme'), isNull);
    expect(store.getIntSync('launch_count'), isNull);
    expect(await store.setString('theme', 'system'), isTrue);
    expect(await store.setInt('launch_count', 4), isTrue);

    expect(store.getStringSync('theme'), 'system');
    expect(store.getIntSync('launch_count'), 4);
  });

  test('provider creates shared preferences store', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(appPreferencesProvider),
      isA<SharedPreferencesStore>(),
    );
  });
}
