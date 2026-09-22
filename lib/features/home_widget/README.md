# Home Widget Feature

Home Widget owns the Android home-screen launcher widget. It mirrors the
Diary daily balance card (kcal and macros left) and offers the compact
quick-eat shortcuts (search, AI, barcode). Tapping the card opens the app.

## Owns

- The render-ready widget snapshot (`application/home_widget_snapshot.dart`)
  and the pure mapper that builds it
  (`application/home_widget_snapshot_mapper.dart`).
- The sync controller that keeps the native widget's saved snapshot up to
  date (`presentation/controllers/home_widget_sync_controller.dart`).
- The silent/verbose preference and its controller
  (`presentation/controllers/home_widget_verbose_mode_controller.dart`).
- The widget-tap action stream and URI parser
  (`application/home_widget_click_action_provider.dart`,
  `application/home_widget_action_uri_codec.dart`).
- The `home_widget` plugin bridge (`data/home_widget_plugin_bridge.dart`) and
  its typed errors (`domain/home_widget_exceptions.dart`).

## Does Not Own

- Diary dashboard computation — reads it only through Diary's public
  `diaryHomeWidgetSummaryProvider`.
- The product search hub, barcode scanner, or AI food estimate flows —
  navigates to them, does not implement them.
- Native widget rendering (Kotlin Glance under
  `android/app/src/main/kotlin/de/yamt/app/homewidget/`) — no Dart code
  renders the widget itself.
- Navigation on widget tap — `lib/app.dart` (the composition root) listens to
  `homeWidgetClickActionProvider` and calls `context.push`.
- The Settings row — Settings renders it through the public edge below.

## Public Edge

- `presentation/widgets/home_widget_verbose_mode_builder.dart`
  (`HomeWidgetVerboseModeBuilder`) gives another feature's surface the
  current silent/verbose value and a toggle. Settings uses it for its row.

`lib/app.dart` (composition root) also wires `homeWidgetSyncControllerProvider`
and `homeWidgetClickActionProvider` directly.

## Providers

- `presentation/controllers/home_widget_sync_controller.dart` —
  `homeWidgetSyncControllerProvider` (`@riverpod`, side effect only: its
  `ref.listen`s on Diary's summary and the verbose preference write the
  snapshot through the plugin bridge). `lib/app.dart` holds a listener for
  the app's lifetime; without one Riverpod pauses its subscriptions and the
  summary gets disposed.
- `presentation/controllers/home_widget_verbose_mode_controller.dart` —
  `homeWidgetVerboseModeControllerProvider` (`@riverpod`, saved in
  `AppPreferences`, same pattern as Diary's `DiaryBalanceDetailsController`).
- `application/home_widget_click_action_provider.dart` —
  `homeWidgetClickActionProvider` (`@riverpod Stream`, kept alive by
  `lib/app.dart`).
- `data/home_widget_plugin_bridge.dart` — `homeWidgetPluginBridgeProvider`
  (`@Riverpod(keepAlive: true)`). Tests override it with a fake that
  implements `HomeWidgetPluginBridge`.

## Accepted Dependencies

- `core/preferences` for the silent/verbose toggle.
- `core/provider` for `clockProvider`.
- `features/diary` for `DiaryHomeWidgetSummary` and
  `diaryHomeWidgetSummaryProvider` (see Diary's README).
- `features/product_search_hub` for `ProductSearchHubInitialIntent`, the
  intent a quick-action tap opens the hub with.
- `home_widget` (pub package) for the native data and click bridge.

## Tests

- `test/features/home_widget/application/`
- `test/features/home_widget/presentation/`

## Legacy

- Android only. An iOS WidgetKit extension is a planned follow-up.
