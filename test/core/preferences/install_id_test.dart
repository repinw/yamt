import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/install_id.dart';

import '../../helpers/memory_app_preferences.dart';

void main() {
  test('two first callers get the same install id, and it stays', () async {
    final preferences = MemoryAppPreferences();

    final (first, second) = await (
      readInstallId(preferences),
      readInstallId(preferences),
    ).wait;

    expect(second, first);
    expect(await readInstallId(preferences), first);
  });
}
