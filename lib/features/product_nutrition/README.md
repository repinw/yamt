# Product Nutrition Feature

Product Nutrition reads a photo of a nutrition table with Firebase AI and
owns the OCR draft/result domain types used to fill product nutrition fields.
The caller takes the photo.

## Owns

- Nutrition label OCR draft/result domain models.
- OCR repository and repository provider for the Firebase AI template call
  (`nutrition-label-template`).
- OCR response parsing and OCR-specific error codes.

## Does Not Own

- Product search UI or manual product form state.
- Inventory item models, global food nutrition models, or persistence of parsed
  nutrition values.
- Scanner receipt capture and review flows.
- Taking the photo (the caller does it) and Firebase AI app setup.

## Public Edge

Other features may consume these public Product Nutrition entry points:

- `NutritionLabelOcrRepository`
- `nutritionLabelOcrRepositoryProvider`
- `NutritionLabelOcrDraft`
- `NutritionLabelOcrResult`
- `NutritionLabelOcrStatus`
- `NutritionLabelOcrErrorCodes`

Tests may override `nutritionLabelTemplateModelClientProvider` to isolate
model calls.

## Rules

- A draft exists only when every mandatory EU value is present: energy in kJ
  and kcal, fat, saturates, carbohydrate, sugars, protein, and salt.
- The app rejects only values that no real label can have
  (`NutritionLabelOcrDraft.isPlausible`). Whether kcal fits the macros is
  checked by the model, because sugar alcohols and alcohol break that rule.

## Providers

- Repository and infrastructure client providers live in `data/` beside
  `NutritionLabelOcrRepository`.
- Domain models stay provider-free in `domain/`.
- This feature has no presentation layer and no feature-level `provider/`
  folder.

## Accepted Dependencies

Product Nutrition depends on Firebase AI for the OCR request.

Current accepted cross-feature use:

- `product_search_hub` may call the OCR repository and apply OCR drafts to
  manual product nutrition fields.

Other features should consume the public edge above instead of reaching into
private parsing helpers.

## Tests

Product Nutrition tests live under `test/features/product_nutrition/`.
