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
- `InventoryShoppingListPage` (finished shopping surface with stock suggestions)
- `application/inventory_quick_eat_data_providers.dart` for repository-backed
  quick-eat inventory data used by integrating features.
- `application/inventory_quick_eat_application.dart` for quick-eat mutations
  used by integrating features. Callers pass the `InventoryItem` or
  `PreparedMeal` they show, so no server read delays the save. The calorie
  entry commit stores read the stock local-first and queue a batch, so eating
  also works offline. Item upserts and activity events also queue their
  batches without waiting for the server. The Diary "eat food" flow sizes a
  new item to the eaten amount before its only write and saves the shared
  catalog product and barcode selection in the background.
- `application/inventory_quick_eat_picker.dart` for quick-eat picker contract
  used by integrating features.
- `presentation/inventory_quick_eat_sheet_picker.dart` for inventory-owned
  quick-eat sheet picker implementation.
- `application/inventory_manual_product_eat_flow_contract.dart` and
  `presentation/inventory_manual_product_eat_coordinator.dart` for manual-product
  completion from product-search integrations.
- `InventoryItemsController`
- `PreparedMealsController`
- `PreparedMealTemplatesController`
- `PreparedMealSelectionController`
- `InventoryActivityEvent` and `InventoryActivityEventRepository`
- Inventory domain types such as `InventoryItem`, `PreparedMeal`, and
  `InventoryItemEatRequest`
- Repository providers from `data/` when tests or app composition need explicit
  overrides
- `InventoryReceiptItemEditorSheet` and `InventoryReceiptCandidatePickerSheet`
  for scanner/inventory receipt-review correction flows.
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
  `presentation/inventory_calorie_stock_adjuster.dart` implements the calories
  `CalorieInventoryStockAdjuster` port: when a logged amount changes, items
  measured in grams or milliliters consume or return the difference, while
  items counted in pieces keep their stock. They share
  `presentation/inventory_controller_access.dart`, which runs an operation on
  the loaded `InventoryItemsController`.
- `provider/` is legacy and should stay empty; do not add new files there.

## Inventory Activity

Activity events are append-only household timeline entries stored under the
effective inventory owner. They record shared stock facts only: actor, item,
amount, timestamp, and before/after stock. Personal calorie diary data remains
owned by `calories` and is not exposed through the activity timeline.

## Shopping Recommendations

- `domain/inventory_replenishment.dart` aggregates product batches by brand and
  product-name matching. Exact names and sufficiently specific whole-word
  variants such as `Eiweißbrot` and `Eiweißbrot - Proteinkorn` share their stock
  total. Partial words and short generic names do not match. Distinct nonempty
  receipt IDs within 180 days are purchase evidence; manual additions and
  duplicate rows on one receipt do not inflate frequency. Only retained
  inventory records can contribute receipt evidence.
- Remaining amounts are normalized to pack equivalents across all batches.
  At most 0.25 packs with activity in the last 60 days triggers replenishment.
  Empty stock is labeled separately from a small positive remaining amount. Additional
  full batches prevent false low-stock suggestions. Deposits, discounts and
  future entries are excluded. Low stock sorts before purchase frequency.
- `application/inventory_shopping_suggestions.dart` owns the live repository
  input and adapts these facts to shoppinglist's public suggestion model.
- `InventoryShoppingListPage` injects that source and retry action into the
  finished shopping page. Shoppinglist does not import inventory.

## Accepted Dependencies

Inventory currently has explicit dependencies on:

- `auth` and `household` for current data owner resolution.
- `calories` for meal type, calorie entry handoff, and prepared meal calorie
  logging. `application/inventory_calorie_nutrient_details.dart` maps an
  item's label nutrients into the calories `CalorieNutrientDetails` so logged
  entries keep them.
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
