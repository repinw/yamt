import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

// The native widget builds these URIs (android/.../homewidget/QuickEatBar.kt):
// homewidget://quick-add?intent=<value>. Any other URI (the card tap sends
// homewidget://open) only opens the app.
const _homeWidgetActionScheme = 'homewidget';
const _homeWidgetActionHost = 'quick-add';
const _homeWidgetActionIntentParam = 'intent';

/// Query values the widget buttons send. Only the intents the widget offers
/// are listed; [ProductSearchHubInitialIntent.launcher] has no widget button.
const Map<String, ProductSearchHubInitialIntent> _intentsByParamValue = {
  'barcode': ProductSearchHubInitialIntent.barcode,
  'search': ProductSearchHubInitialIntent.search,
  'ai': ProductSearchHubInitialIntent.ai,
};

/// Parses a widget-click URI into the intent to open, or `null` when [uri]
/// is not a home-widget quick-action URI.
ProductSearchHubInitialIntent? parseHomeWidgetActionUri(Uri? uri) {
  if (uri == null ||
      uri.scheme != _homeWidgetActionScheme ||
      uri.host != _homeWidgetActionHost) {
    return null;
  }
  return _intentsByParamValue[uri
      .queryParameters[_homeWidgetActionIntentParam]];
}
