# Scanner Feature

Scanner owns receipt input, receipt analysis, receipt review flow state, shared
receipt intents, and the UI surfaces that turn a receipt into reviewed inventory
items.

## Owns

- Receipt input models, capture results, batch flow state, and review drafts.
- Receipt analysis parsing, clients, repositories, and mappers.
- Receipt review resolution and persistence orchestration.
- Camera/file capability providers and pending shared-receipt intents.
- Receipt flow controllers, review runners, shared receipt listener, review
  page, dialogs, and review widgets.

## Does Not Own

- Inventory item domain rules outside receipt review persistence.
- Global food matching and candidate ownership.
- Calorie product cache storage.
- Home or Inventory launch buttons that start scanner flows.

## Public Edge

Other features may consume these public Scanner entry points:

- `presentation/controllers/receipt_capture_flow_controller.dart`
- `presentation/controllers/receipt_batch_flow_controller.dart`
- `application/shared_receipt_service.dart`
- `presentation/shared_receipt_listener.dart`
- `presentation/shared_receipt_flow_runner.dart`
- `presentation/receipt_batch_flow_runner.dart`
- `presentation/receipt_review_flow_runner.dart`
- `presentation/inventory_receipt_review_page.dart`
- `provider/receipt_input_capabilities.dart`
- Receipt domain models under `domain/`

## Providers

- Repository providers live in `data/`.
- Receipt review and shared receipt services live in `application/`.
- Capture and batch controllers live in `presentation/controllers/`.
- `provider/` is legacy and currently holds input capability and pending
  shared-intent state providers. Move those in a follow-up cleanup when their
  ownership is revisited.

## Accepted Dependencies

Scanner currently has explicit dependencies on:

- `core` for routing, constants, and shared UI primitives.
- `inventory` for saving reviewed receipt items and matching global foods.
- `calories` for calorie product cache persistence during receipt review.

Current accepted consumers include Home, Inventory, app startup, router tests,
and integration tests. Consumers should use the public controllers, flow
runners, and domain models instead of wiring scanner internals directly.

## Tests

Scanner tests live under `test/features/scanner/`, matching the owner layer:
`data/`, `domain/`, `application/`, `presentation/`, and
`presentation/controllers/`.

## Migration Notes

- Receipt capture and batch controllers moved from `provider/` to
  `presentation/controllers/`.
- Shared receipt service moved from `provider/` to `application/`.
- Remaining files in `provider/` are legacy transition files.
