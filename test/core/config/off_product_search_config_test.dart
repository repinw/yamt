import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/config/off_product_search_config.dart';

void main() {
  test('uses https as default OFF product search endpoint', () {
    final uri = resolveOffProductSearchUri();

    expect(uri, isNotNull);
    expect(uri!.scheme, 'https');
    expect(uri.host, 'api.yamt.de');
    expect(uri.port, 443);
    expect(uri.path, '/search');
  });
}
