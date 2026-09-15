# Product Search Hub

Einheitliche Produktsuche, Produkteditor, KI-Drafterstellung und Barcode-Assistent.

## Owns

- Einheitlicher Einstiegspunkt (`ProductSearchHubPage`) und Vollbildsuche (`ProductSearchHubSearchPage`).
- Manueller Produkteditor (`InventoryReceiptManualProductEditorPage`), Formulare und Nährwertvalidierung.
- KI-gestützte Produktdrafterstellung (`ManualProductAiSearchPage`, `ProductAiSearchService`, `FirebaseProductAiSearchRepository`).
- Koordination der Kontext-Modi (`inventory`, `diary`, `selection`).
- Aussteuerungsregeln für Barcode-Scan, zuletzt ausgewählte Artikel und eigene Artikeleingabe.
- Barcode-Kandidaten-Scanner, Kandidaten-Karten und Aktionen für Suchergebnisse.
- Kind-Routen (`AppRoutes.productSearchChildFlow`) für modale Editor- und KI-Suchen.
- Abstraktion des Datenzugriffs via `ProductSearchGateway` und `ProductSearchHubCompletionHandler`.

## Does Not Own

- Vorrats-Persistenz und Repository (`inventory`).
- Tagebuch- und Kalorien-Persistenz (`diary`, `calories`).
- Ausführung von fachlichen Seiteneffekten fremder Features (keine direkten Controller-Imports wie `InventoryItemsController` oder `CalorieEntriesController`).
- Kamera- und generische Barcode-Overlay-Engine (`core/widgets/barcode_scanner/`).
- Nährwert-Etiketten-OCR (`product_nutrition`).

## Public Edges

- `ProductSearchHubPage` für Hauptsuch- und Auswahlrouten.
- `ProductSearchHubSearchPage` für die animierte Suchoberfläche.
- `ManualProductSearchRouteArgs`, `buildManualProductSearchRoutePage` für Kind-Flows.
- `ProductSearchHubSavedSelection` und `ProductSearchHubCompletionResult` für Entkopplung und typsichere Resultate.
- `ProductSearchHubCompletionHandler` (`abstract interface class`) für modusspezifische Abschlusslogik.
- `productSearchHubCompletionHandlerProvider` & `productSearchGatewayProvider` zur Bereitstellung der Handler und Gateways.
- `InventoryReceiptManualProductResult` für Rückgabewerte bearbeiteter Artikel.

## Modus- & Entkopplungsregeln

Das Feature führt keine fremden Controller-Mutationen selbst durch. Die fachlichen Seiteneffekte gehören dem Aufrufer (`caller-owned side effects`):

- **Inventory-Modus**:
  Titel ist "Zum Vorrat hinzufügen". Delegiert via `productSearchHubCompletionHandlerProvider` an `InventoryProductSearchHubCompletionHandler` (`features/inventory`), welcher `InventoryItemsController` aktualisiert.
- **Diary-Modus**:
  Titel ist "Lebensmittel essen". Delegiert via `productSearchHubCompletionHandlerProvider` an `DiaryProductSearchHubCompletionHandler` (`features/diary`), welcher `inventoryBackedCalorieEntrySaveFlow` ausführt.
- **Selection-Modus**:
  Titel ist "Produkt hinzufügen". Verwendet den Standard-Handler (`DefaultProductSearchHubCompletionHandler`), schließt die Ansicht (`pop`) und gibt das Resultat an den Aufrufer zurück.

## Tests

- Controller-Tests: `test/features/product_search_hub/presentation/controllers/`
- Application-Tests: `test/features/product_search_hub/application/`
- Domain-Tests: `test/features/product_search_hub/domain/`
- Data-Tests: `test/features/product_search_hub/data/`
- Widget- & Flow-Tests: `test/features/product_search_hub/presentation/`

