# Product Search Feature

Product search owns the manual product lookup, barcode-assisted product
selection, AI product draft review, and product-search-specific form state used
when an inventory flow needs a product match or manual nutrition input.

## Owns

- Manual product search launcher, editor, form widgets, and AI search page.
- Manual product search controller, state, config, and save payload models.
- Product AI search repository, parsed AI search domain models, and AI result
  builders.
- Application services for AI draft generation.
- Product-search-specific helpers for normalizing manual text and weight input.

## Does Not Own

- Inventory persistence, inventory item repository implementation, and barcode
  scanner UI. Those remain owned by `inventory`.
- Receipt review item drafts, receipt candidate picker widgets, receipt
  product-selection widgets, and manual recent-item aggregation. Those remain
  owned by `inventory`.
- Nutrition label OCR repository and OCR result models. Those remain owned by
  `product_nutrition`.
- App routing setup. Product search exposes pages/widgets for route owners to
  compose.

## Public Edges

- `InventoryReceiptManualProductPage` from
  `presentation/widgets/manual_product_search_page/manual_product_search_page.dart`.
- `InventoryReceiptManualProductResult` and
  `InventoryReceiptManualProductInitialIntent` via
  `presentation/widgets/manual_product_search_page_types.dart`.
- `InventoryReceiptManualProductAction` via
  `presentation/controllers/manual_product_search_models.dart`.
- `InventoryManualAddPage`, `InventoryManualAddRouteArgs`, and
  `InventoryManualAddInitialAction` via
  `presentation/inventory_manual_add_page.dart` for inventory-owned add flows
  that are routed by app composition.

Other features should use these entry points instead of assembling internal
form widgets or controller state directly.

## Providers

- `inventoryReceiptManualProductControllerProvider` lives in
  `presentation/controllers/manual_product_search_controller.dart`.
- `productAiSearchRepositoryProvider` lives in
  `data/product_ai_search_repository.dart`.
- `productAiSearchServiceProvider` lives in
  `application/product_ai_search_service.dart`.
- AI nutrition selection and result-building helpers live in `application/`.

## Navigation

The app entry point is routed by `go_router` through the owning feature. Nested
manual-product child flows use `manual_product_search_page_route.dart` and the
`AppRoutes.productSearchChildFlow` `go_router` route so temporary
launcher/editor/AI pages keep typed results and no-animation behavior inside
the current modal flow. Do not call `Navigator.push` from individual
product-search widgets; use the route helper instead.

## OFF Result Grading

Manual search and barcode lookup must grade OFF products instead of hiding
them only because nutrition is incomplete.

- Show plausible OFF matches even when nutrition fields are missing.
- Mark each result with a nutrition grade: missing nutrition, missing calories,
  incomplete nutrition, complete nutrition, or verified nutrition.
- Allow inventory-oriented flows to continue with incomplete nutrition when
  the product identity and package data are useful.
- Treat eat-now and calorie-tracking flows as nutrition-dependent. If kcal or
  other required fields are missing, route the user into the editor so they can
  scan a nutrition label or fill the fields before saving.
- Collapse duplicate OFF rows only when they share the same normalized barcode,
  package size does not conflict, overlapping nutrition values do not conflict,
  and one row has either a better nutrition grade or more known fields within
  the same grade without losing known nutrition fields.
- Do not hide rows only because the name or brand looks similar. Different
  barcode, package size, country recipe, or conflicting nutrition values are
  separate candidates.
- A barcode plus confirmed nutrition-label OCR produces a complete local draft,
  not a verified global product. Global verification should require repeated
  independent confirmations of the same barcode, package size, and normalized
  nutrition values without recent conflicts.

## Accepted Dependencies

- Depends on `inventory` domain/data for `InventoryItem`,
  `OffProductSearchResult`, amount parsing, recent item reads, and barcode
  candidate conversion.
- Depends on `inventory` presentation for the barcode scanner surface and quick
  eat configuration.
- Depends on `product_nutrition` for nutrition label OCR.
- Depends on `core` for shared widgets, theme spacing constants, voice search,
  barcode utilities, and eat-selection types.

Keep these dependencies narrow. New consumers outside this feature should prefer
the public page/result types listed above.

## Tests

- Controller tests:
  `test/features/product_search/presentation/controllers/`.
- Domain tests:
  `test/features/product_search/domain/`.
- Data tests:
  `test/features/product_search/data/`.
- Widget/page tests:
  `test/features/product_search/presentation/`.
