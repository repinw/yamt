import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/settings/data/secondary_auth_client.dart';

void main() {
  test('secondaryAuthClientProvider returns default implementation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final client = container.read(secondaryAuthClientProvider);
    expect(client, isA<SecondaryAuthClient>());
  });

  test('secondaryAuthClientProvider hash method is callable', () {
    expect(
      secondaryAuthClientProvider.debugGetCreateSourceHash(),
      isA<String>(),
    );
  });
}
