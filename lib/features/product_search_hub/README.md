# Product Search Hub

Einheitliche Produktsuche, Produkteditor, KI-Drafterstellung und Barcode-Assistent.

## Owns

- Einheitlicher Einstiegspunkt (`ProductSearchHubPage`) und Vollbildsuche (`ProductSearchHubSearchPage`).
- Manueller Produkteditor (`ManualProductSearchEditorPage`), Formulare und Nährwertvalidierung.
- KI-gestützte Produktdrafterstellung (`ProductAiSearchPage`, `ProductAiSearchService`, `ProductAiSearchRepository`).
- Koordination der Kontext-Modi (`inventory`, `diary`, `selection`).
- Aussteuerungsregeln für Barcode-Scan, zuletzt ausgewählte Artikel und eigene Artikeleingabe.
- Barcode-Kandidaten-Scanner, Kandidaten-Karten und Aktionen für Suchergebnisse.
- Kind-Routen (`AppRoutes.productSearchChildFlow`) für modale Editor- und KI-Suchen.

## Does Not Own

- Vorrats-Persistenz und Repository (`inventory`).
- Kamera- und generische Barcode-Overlay-Engine (`core/widgets/barcode_scanner/`).
- Nährwert-Etiketten-OCR (`product_nutrition`).

## Public Edges

- `ProductSearchHubPage` für Hauptsuch- und Auswahlrouten.
- `ProductSearchHubSearchPage` für die animierte Suchoberfläche.
- `ManualProductSearchRouteArgs`, `buildManualProductSearchRoutePage` für Kind-Flows.
- `InventoryReceiptManualProductResult` für Rückgabewerte bearbeiteter Artikel.

## Modus-Regeln

- **Inventory-Modus**:
  Titel ist "Zum Vorrat hinzufügen"; Save-Result wird direkt zum Vorrat hinzugefügt.
- **Diary-Modus**:
  Titel ist "Lebensmittel essen"; Save-Result läuft durch den Eat Flow.
- **Selection-Modus**:
  Titel ist "Produkt hinzufügen"; der bearbeitete Result wird an den Aufrufer zurückgegeben.

## Tests

- Controller-Tests: `test/features/product_search_hub/presentation/controllers/`
- Domain-Tests: `test/features/product_search_hub/domain/`
- Data-Tests: `test/features/product_search_hub/data/`
- Widget- & Flow-Tests: `test/features/product_search_hub/presentation/`

