# Minimal Barcode Resolver (Genkit)

Diese Functions machen nur noch:

1. Queue aus `users/{uid}/barcode_enrichment_requests/{fingerprint}`
2. Eine Gemini-Batch-Anfrage (mit Websuche)
3. EAN-Kandidaten speichern in
   `food_fingerprint_catalog/{fingerprint}`

Kein Open Food Facts. Keine Modell-/Quellen-Fallbacks.

## Aktivierung

1. Projekt auswählen

```bash
firebase use mealtrack-4b239
```

2. APIs aktivieren

- `aiplatform.googleapis.com`
- `cloudfunctions.googleapis.com`
- `run.googleapis.com`
- `eventarc.googleapis.com`
- `cloudbuild.googleapis.com`

3. IAM

Runtime Service Account:
`<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`

Rolle:
- `Vertex AI User` (`roles/aiplatform.user`)

4. Dependencies installieren

```bash
npm --prefix functions install
```

## Parameter

Beim Deploy oder in `.env.<project>`:

- `BARCODE_TEMPLATE_MODEL=gemini-3.1-pro-preview`
- `BARCODE_TEMPLATE_LOCATION=global`
- `BARCODE_TEMPLATE_USE_GOOGLE_SEARCH=true`
- `BARCODE_TEMPLATE_MAX_OUTPUT_TOKENS=4096`
- `BARCODE_TEMPLATE_MAX_BATCH_ITEMS=40`
- `BARCODE_TEMPLATE_MIN_CANDIDATES=1`
- `ENABLE_GENKIT_FIREBASE_TELEMETRY=true`

## Deploy

```bash
firebase deploy --only functions:default --project mealtrack-4b239
```

## Datenfluss

- Request-Dokument wird auf globale Queue gemerged:
  `barcode_enrichment_jobs/{fingerprint}`
- Runner nimmt ein Batch aus allen `queued` Jobs.
- Ein Gemini-Call liefert pro Fingerprint:
  `ean_candidates: [ ... ]`
- Global gespeichert:
  `food_fingerprint_catalog/{fingerprint}`
  mit
  - `barcode` (Top-Kandidat oder `null`)
  - `ean_candidates` (Liste)
- User-Request wird auf
  - `resolved` + `resolved_barcode`
  - oder `needs_user_barcode`
  gesetzt.

