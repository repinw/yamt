import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/home_widget/application/home_widget_action_uri_codec.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

void main() {
  test('parses the quick-add uris the widget buttons send', () {
    expect(
      parseHomeWidgetActionUri(
        Uri.parse('homewidget://quick-add?intent=barcode'),
      ),
      ProductSearchHubInitialIntent.barcode,
    );
    expect(
      parseHomeWidgetActionUri(
        Uri.parse('homewidget://quick-add?intent=search'),
      ),
      ProductSearchHubInitialIntent.search,
    );
    expect(
      parseHomeWidgetActionUri(Uri.parse('homewidget://quick-add?intent=ai')),
      ProductSearchHubInitialIntent.ai,
    );
  });

  test('parses the iOS uris, which carry the plugin homeWidget item', () {
    expect(
      parseHomeWidgetActionUri(
        Uri.parse('homewidget://quick-add?intent=barcode&homeWidget'),
      ),
      ProductSearchHubInitialIntent.barcode,
    );
    expect(
      parseHomeWidgetActionUri(Uri.parse('homewidget://open?homeWidget')),
      isNull,
    );
  });

  test('returns null for the card tap, which only opens the app', () {
    expect(parseHomeWidgetActionUri(Uri.parse('homewidget://open')), isNull);
  });

  test('returns null for a null, unrelated or unknown uri', () {
    expect(parseHomeWidgetActionUri(null), isNull);
    expect(parseHomeWidgetActionUri(Uri.parse('https://example.com')), isNull);
    expect(
      parseHomeWidgetActionUri(Uri.parse('homewidget://quick-add?intent=nope')),
      isNull,
    );
  });
}
