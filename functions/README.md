# Inventory Barcode Resolver (Direct Call)

Diese Functions machen nur noch einen direkten Single-Item-Flow:

1. App ruft Callable `resolveInventoryItemBarcode` auf.
2. Function holt genau ein `inventory_item`.
3. Ein Gemini-Call mit Websuche sucht EAN-Kandidaten.
4. Ergebnis wird direkt im Item gespeichert:
   `users/{uid}/inventory_items/{itemId}`.

Keine Queue. Kein `barcode_enrichment_jobs`. Kein `system_runtime`.

## Voraussetzungen

- `aiplatform.googleapis.com`
- `cloudfunctions.googleapis.com`
- `run.googleapis.com`
- `eventarc.googleapis.com`
- `cloudbuild.googleapis.com`

Runtime Service Account:
`<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`

Benötigte Rolle:
- `roles/aiplatform.user`

## Installieren

```bash
npm --prefix functions install
```

## Deploy

```bash
firebase deploy --only functions:resolveInventoryItemBarcode --project mealtrack-4b239
```

## Callable Payload

```json
{
  "itemId": "inventory_doc_id",
  "fingerprint": "optional",
  "itemName": "optional",
  "brand": "optional",
  "trigger": "manual_search"
}
```

## Response

```json
{
  "success": true,
  "found": true,
  "barcode": "1234567890123",
  "candidates": ["1234567890123", "1234567890128"]
}
```
