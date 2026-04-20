# Product AI Search

## Summary
- Add `+` action to editable manual search bar in manual product editor.
- Tap opens dialog where user enters free text like `Doener Haehnchen`.
- App calls Firebase AI template directly from Flutter via `firebase_ai`.
- AI returns review draft, not saved item.
- Review draft shows ingredient breakdown, total weight, total kcal range, and
  estimated nutrition.
- User adjusts total kcal with slider, reviews generated fields, then saves
  through existing manual add flow.

## Implementation Changes
- Create new doc path `feature_description/ai-search/product-ai-search.md`
  during execution, because `feature_description/` does not exist yet.
- Add new product-search AI repository/provider in
  `lib/features/product_search/...`, following existing direct template pattern
  already used for receipt analysis and nutrition OCR.
- Use static template config client in v1, same style as current OCR template
  setup.
- Add parsed AI draft model with:
  - generated name
  - optional brand
  - ingredient rows with label, amount text, grams, kcal min/max
  - total grams
  - total kcal min/max/default
  - macro estimate for total portion
  - per100 nutrition estimate derived from that portion
- Extend manual product controller state with:
  - AI loading/error state
  - active AI draft
  - kcal slider min/max/current
  - derived portion/per100 nutrition values
  - visible estimate breakdown data
- Add always-visible `+` icon to editable manual search bar next to scan
  button.
- Add prompt dialog prefilling current search text when available.
- On AI success:
  - patch manual form with generated name
  - patch weight / serving data
  - patch nutrition fields
  - show estimate review card with breakdown table and total row
  - set nutrition quality to `GlobalFoodNutritionQualityStatus.unverified`
- Add kcal slider below breakdown:
  - range = AI total kcal min/max
  - initial value = AI default kcal
  - moving slider rescales portion macros proportionally
  - app recomputes per100 nutrition from selected kcal/macros and total grams
- Manual edits remain authoritative after user changes fields.
- AI regenerate action replaces previous AI draft state.
- Update manual save flow to support barcode-less items:
  - remove hard stop requiring normalized barcode in manual add persistence
  - save `InventoryItem` with `barcode: null` and empty `barcodeCandidates`
  - save `GlobalFoodItem` with generated id like `manual-food-<uuid>`
  - skip barcode candidate recording when barcode absent
- Do not persist ingredient breakdown rows. They are review-only UI state.

## Public / Behavioral Interfaces
- New AI repository contract for `generateFoodFromText`.
- New AI draft model for text-generated food estimate.
- Manual add result/save path must tolerate saved items without barcode.
- UI behavior change: editable manual search bar always includes `+` action.

## Test Plan
- Repository tests:
  - valid AI JSON parse
  - invalid JSON
  - missing ingredient rows
  - missing total grams or kcal range
  - timeout / request failure mapping
- Controller tests:
  - applying AI draft patches form fields
  - slider rescales macros
  - per100 nutrition recomputes correctly
  - manual field edits override AI values
  - regenerate replaces prior draft
  - saved nutrition marked `unverified`
- Widget tests:
  - `+` button visible in editor
  - dialog prefills current search text
  - loading / error states render
  - ingredient breakdown table and total row render
  - slider changes displayed kcal and form values
  - barcode-less AI item can be saved
- Inventory/manual add tests:
  - save succeeds with no barcode
  - no barcode candidate write happens
  - recent-item dedupe still works for AI-created manual foods

## Assumptions
- v1 target = Android + iOS.
- No Cloud Functions.
- Review-first only, no direct AI auto-save.
- Ingredient breakdown shown in UI, but not persisted.
- AI estimate is approximate, so persisted nutrition remains `unverified`.
- AI response must include usable ingredient breakdown plus total grams and kcal
  range; otherwise generation fails.
