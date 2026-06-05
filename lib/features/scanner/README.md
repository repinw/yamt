# Scanner Feature

Scanner owns receipt capture, receipt AI analysis, receipt batch processing,
shared receipt intents, and the receipt review flow.

## Owns

- Receipt input selection for camera, gallery, files, and shared intents.
- Receipt analysis repositories, parser contracts, and AI request preparation.
- Receipt review draft mapping, candidate-resolution orchestration, and
  persistence coordination for inventory-owned review drafts.
- Receipt review pages, widgets, flow runners, and scanner-specific UI state.
- Batch receipt processing and review state for multiple receipt inputs.

## Does Not Own

- Inventory item storage and global food catalog persistence. Scanner delegates
  those writes to inventory repositories and services.
- Product search internals. Scanner launches the product-search hub public
  route for user-driven product lookup.
- Calorie diary editing UI. Scanner only writes product nutrition handoff data
  needed by calorie flows.

## Public Edge

Other features may consume these scanner entry points:

- `InventoryReceiptReviewPage`
- `ReceiptCaptureFlowController`
- `ReceiptBatchFlowController`
- `SharedReceiptFlowRunner`
- Receipt domain models such as `ReceiptInputSelection` and
  `ReceiptAnalysisExtraction`

Callers should not assemble scanner internal review widgets directly unless the
widget is documented as a reusable scanner surface.

## Providers

- Repository providers live in `data/`.
- Application service providers live in `application/`.
- Controller providers currently live in legacy `provider/`; do not add new
  controller files there unless moving them would create unrelated churn.
- Domain stays provider-free and contains pure models/helpers.

## Accepted Dependencies

Scanner currently has explicit dependencies on:

- `inventory` for `InventoryItem`, `OffProductSearchResult`, global food
  matching, inventory-owned review drafts, inventory persistence, receipt alias
  persistence, manual product result models, and inventory-owned receipt
  correction sheets.
- `product_search_hub` for the public selection route used during receipt
  review fallback and product correction.
- `calories` for product nutrition cache handoff after reviewed receipt items
  are saved.

These dependencies should stay small and flow through public edges, application
services, or repository interfaces.

## Tests

Scanner tests live under `test/features/scanner/`. Receipt-review persistence
tests that exercise inventory-owned global food behavior live under
`test/features/inventory/`.
