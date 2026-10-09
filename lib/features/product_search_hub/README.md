# Product Search Hub

Einheitliche Produktsuche, Produkteditor, KI-Drafterstellung und Barcode-Assistent.

## Owns

- Eine Produktsuche-Seite (`ProductSearchHubPage`) mit Suchfeld, Barcode-, KI- und Eigenes-Produkt-Aktionen, zuletzt ausgewählten Produkten; ein Produkt pro Besuch (#519, #532).
- Manueller Produkteditor (`InventoryReceiptManualProductEditorPage`) im Etikett-Look der Eat-Seite: Kopf mit Bild, Marke, Name und Packung, darunter zwei Foto-Kacheln (Vorderseite, Nährwerttabelle) mit Barcode-Zeile und das Nährwertetikett mit Eingaben je 100 g. Die sieben EU-Pflichtwerte sind Pflicht.
- Produktfotos (`ProductPhotoRepository`, `ManualProductPhotoController`): Kamera, Barcode-Suche im Foto (`mobile_scanner`), KI-Lesen der Vorderseite über das Server-Template `product-front-template`, Upload nach Firebase Storage `product_images/{uid}/{photoId}/` als geteiltes Produktbild.
- KI-Schätzung von Essen aus Fotos und/oder Beschreibung (`ManualProductAiSearchPage`, `FoodEstimateController`, `FoodEstimateRepository` mit dem Firebase-AI-Server-Template `food-estimate-template`). Das Ergebnis öffnet im Eat-Dialog aus `inventory` (`FoodEstimateResultPage`).
- Koordination der Kontext-Modi (`inventory`, `diary`, `selection`, `mealFood`).
- Aussteuerungsregeln für Barcode-Scan, zuletzt ausgewählte Artikel und eigene Artikeleingabe.
- Barcode-Kandidaten-Scanner, Kandidaten-Karten und Aktionen für Suchergebnisse.
- Kind-Routen (`AppRoutes.productSearchChildFlow`) für modale Editor- und KI-Suchen.
- Abstraktion des Datenzugriffs via `ProductSearchGateway`.
- Abschluss eines gewählten Lebensmittels je Modus (`product_search_hub_completion_flow.dart`): Vorrat speichern, im Tagebuch essen oder planen, über die Abläufe aus `inventory`.

## Does Not Own

- Vorrats-Persistenz und Repository (`inventory`).
- Tagebuch- und Kalorien-Persistenz (`diary`, `calories`).
- Ausführung von fachlichen Seiteneffekten fremder Features (keine direkten Controller-Imports wie `InventoryItemsController`).
- Kamera- und generische Barcode-Overlay-Engine (`core/widgets/barcode_scanner/`).
- Nährwert-Etiketten-OCR (`product_nutrition`).

## Public Edges

- `ProductSearchHubPage` für alle Such- und Auswahlrouten.
- `ManualProductSearchRouteArgs`, `buildManualProductSearchRoutePage` für Kind-Flows.
- `ProductSearchHubCompletionResult` für Entkopplung und typsichere Resultate.
- `productSearchGatewayProvider` zur Bereitstellung des Gateways.
- `InventoryReceiptManualProductResult` für Rückgabewerte bearbeiteter Artikel.

## Modus- & Entkopplungsregeln

Das Feature führt keine fremden Controller-Mutationen selbst durch. Vorrat- und Tagebuch-Modus schließen über die Speicher- und Eat-Abläufe aus `inventory` ab, das in der Feature-Reihenfolge vor dem Hub liegt:

- **Inventory-Modus**:
  Titel ist "Zum Vorrat hinzufügen". `completeProductSearchHubResult` speichert das Produkt über `saveManualProductResultToInventory` (`inventory`).
- **Diary-Modus**:
  Titel ist "Lebensmittel essen". `completeProductSearchHubResult` speichert den Eintrag über `saveManualProductResultForEatFlow` (`inventory`) zusammen mit dem Bestand, an einem späteren Tag als Plan.
- **Selection-Modus**:
  Titel ist "Produkt hinzufügen". Speichert nichts, schließt die Ansicht (`pop`) und gibt das Resultat an den Aufrufer zurück.
- **MealFood-Modus** (`AppRoutes.homeFoodPick`, "Kombinieren" im Artikel-Hub):
  Titel ist "Produkt hinzufügen". Ein Treffer mit vollständigem Etikett überspringt den Editor und öffnet die Eat-Seite aus `inventory` mit "Hinzufügen" und "Bearbeiten" (`product_search_hub_meal_food_flow.dart`). "Bearbeiten" öffnet den Editor und kehrt zur Eat-Seite zurück. Die Ansicht schließt mit einem `InventoryMealFoodPick` (Produkt und eingegebene Menge), ohne etwas zu speichern.

## Tests

- Controller-Tests: `test/features/product_search_hub/presentation/controllers/`
- Application-Tests: `test/features/product_search_hub/application/`
- Domain-Tests: `test/features/product_search_hub/domain/`
- Data-Tests: `test/features/product_search_hub/data/`
- Widget- & Flow-Tests: `test/features/product_search_hub/presentation/`

