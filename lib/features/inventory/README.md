# Inventory Feature

Inventory owns food stock, prepared meals, global food matching, receipt aliases,
discard events, and inventory-backed calorie handoff context.

## Owns

- Inventory item domain models, amount parsing, consumption, discard events.
- Household inventory activity events and timeline UI for shared stock changes.
- Prepared meal domain models and mutation workflows.
- Inventory repositories and stores for Firestore-backed inventory data.
- Inventory pages, widgets, controllers, and presentation-only helpers.
- Global food item matching and serving suggestion persistence used by
  inventory flows.

## Does Not Own

- Authentication identity or household membership. Inventory consumes auth and
  household public providers for data ownership.
- Calorie log storage and calorie entry editing UI. Inventory builds handoff
  context and delegates persistence to calories flows.
- Scanner capture/review. Inventory may launch scanner public surfaces.
- Product search internals. Inventory may compose product-search public pages
  for manual product lookup.
- Shopping list persistence. Inventory may call shopping-list public operations.

## Public Edge

Other features may consume these public Inventory entry points:

- `InventoryPage`
- `InventoryItemsController`
- `PreparedMealsController`
- `PreparedMealTemplatesController`
- `PreparedMealSelectionController`
- `InventoryActivityEvent` and `InventoryActivityEventRepository`
- Inventory domain types such as `InventoryItem`, `PreparedMeal`, and
  `InventoryItemEatRequest`
- Repository providers from `data/` when tests or app composition need explicit
  overrides
- `PreparedMealCover` for features that display prepared-meal thumbnails.
- `AppInventoryEatActionColors` and `AppInventoryBuyAgainActionColors` for
  inventory action semantics shared with cookflow.

Callers should not assemble Inventory internal row/card widgets unless they are
already documented as a reusable presentation surface.

## Providers

- Repository providers live in `data/`.
- Use-case/service providers live in `application/`.
- Controller providers live in `presentation/controllers/`.
- Controller-wired calorie save/delete/bridge adapters live in `presentation/`
  because they coordinate presentation controllers with inventory persistence.
- `provider/` is legacy and should stay empty; do not add new files there.

## Inventory Activity

Activity events are append-only household timeline entries stored under the
effective inventory owner. They record shared stock facts only: actor, item,
amount, timestamp, and before/after stock. Personal calorie diary data remains
owned by `calories` and is not exposed through the activity timeline.

## Accepted Dependencies

Inventory currently has explicit dependencies on:

- `auth` and `household` for current data owner resolution.
- `calories` for meal type, calorie entry handoff, and prepared meal calorie
  logging.
- `shoppinglist` for add-to-shopping-list actions from inventory rows.
- `recipes` for template ingredient parsing.

These dependencies are migration-reviewed. New dependencies should be added only
with a README note and should avoid new cycles.

## Tests

Inventory tests live under `test/features/inventory/`. Controller tests live
under `test/features/inventory/presentation/controllers/`.

## Migration Notes

- Legacy controller files were moved from `lib/features/inventory/provider/` to
  `lib/features/inventory/presentation/controllers/`.
- Manual Riverpod providers were migrated to code-generated providers where the
  feature owned the implementation.
- Hand-written UI `part` files were split into normal widget files. Generated
  `*.g.dart` and `*.freezed.dart` parts remain allowed.
