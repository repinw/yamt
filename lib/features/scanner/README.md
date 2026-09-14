# Scanner Feature

Scanner owns receipt capture, text extraction, receipt structuring,
and the interactive receipt review flow.

## Owns

- Receipt input selection for camera, gallery, files (PDF/images), and platform share intents.
- Local text extraction (on-device ML Kit OCR and direct vector text extraction from PDF).
- Parsing raw text into structured receipt models (`ScannedReceipt`, `ReceiptLineItem`) via Google Generative AI (Gemini Flash).
- Interactive receipt review flow, item editing, status management, price adjustments, and review state (`ReceiptReviewController`).
- Flow coordination and UI transitions (`ReceiptScanFlowCoordinator`).

## Does Not Own

- Inventory item storage and global food catalog persistence. Scanner delegates
  all writes to inventory services via `ReceiptStorageGateway`.
- Product catalog search and fuzzy matching internals. Scanner resolves candidates
  via `ReceiptProductResolver` and delegates manual product creation / catalog editing via `ReceiptManualProductPicker`.
- Calorie diary editing or nutrition cache persistence.

## Public Edge

Other features may consume these scanner entry points:

- Domain models: `ScannedReceipt`, `ReceiptLineItem`, `ProductCandidate`.
- Decoupled contracts: `ReceiptProductResolver`, `ReceiptManualProductPicker`, `ReceiptStorageGateway`, `ReceiptTextExtractor`, `ReceiptStructuredParser`.
- Presentation flow & UI:
  - `ReceiptScanFlowCoordinator` (entry point for camera scan and file upload flows)
  - `ReceiptReviewPage` (primary review screen)
  - `SharedReceiptListener` (app-level shell listener for incoming file share intents)
  - `receiptCameraSupportedProvider` (platform camera check)

## Providers

- **Data Layer** (`data/receipt_gateway_providers.dart`):
  - `receiptProductResolverProvider` (host adapter)
  - `receiptManualProductPickerProvider` (host adapter)
  - `receiptStorageGatewayProvider` (host adapter)
  - `receiptTextExtractorProvider` (defaults to `MlKitReceiptTextExtractor`)
  - `receiptStructuredParserProvider` (defaults to `GoogleAiReceiptParser`)
- **Presentation Layer**:
  - `receiptReviewControllerProvider` (`presentation/controllers/receipt_review_controller.dart`)
  - `receiptScanFlowCoordinatorProvider` (`presentation/flow/receipt_scan_flow_coordinator.dart`)
  - `receiptCameraSupportedProvider` (`presentation/flow/receipt_camera_supported.dart`)
  - `sharedReceiptServiceProvider` (`presentation/shared/shared_receipt_service.dart`)
  - `pendingSharedReceiptPathsProvider` (`presentation/shared/pending_shared_receipt_paths.dart`)
- **Domain Layer**:
  - Provider-free. Contains only pure models and `abstract interface class` contracts.

## Dependencies & Adapters

- The core scanner logic is decoupled from persistence and concrete backends via domain contracts (`abstract interface class`).
- Yamt-specific host adapters are colocated in `data/adapters/`:
  - `YamtReceiptStorageGateway` connects to `InventoryItemRepository` and `GlobalFoodItemRepository`.
  - `YamtReceiptProductResolver` connects to `GlobalFoodItemMatcher` and `OffProductSearchRepository`.
  - `YamtReceiptManualProductPicker` opens the host product search / manual item creation sheets.
- `SharedReceiptListener` wraps the root router, listens for share intents, runs the scan coordinator, and invalidates `inventoryItemsControllerProvider` upon successful save.
- `ReceiptBarcodeScanner` wraps `InventoryBarcodeScannerPage` for barcode matching during receipt review.

## Migration Notes

This reworked scanner feature completely replaces the legacy scanner architecture:
- Replaced the legacy monolithic `InventoryReceiptReviewSheet` (which had 760+ line widgets and 3400+ line test files) with 16 modular, focused widgets (< 270 lines each).
- Replaced the legacy manual provider architecture and state machines with clean Riverpod `@Riverpod` notifiers (`ReceiptReviewController`).
- Introduced decoupled contracts with dedicated fakes (`test/features/scanner/fakes/`), enabling isolated, blazing-fast unit and widget testing without Firestore or network dependencies.
- Unified single-image, multi-image, PDF, and share-intent inputs under `ReceiptScanFlowCoordinator`.

## Tests

All scanner unit and widget tests live under `test/features/scanner/`.
