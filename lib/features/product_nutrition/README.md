# Product Nutrition Feature

Product Nutrition owns nutrition-label OCR capture, model request wiring, and
OCR draft/result domain types used to fill product nutrition fields.

## Owns

- Nutrition label OCR draft/result domain models.
- OCR repository and repository provider for camera capture and Firebase AI
  template calls.
- OCR response parsing and OCR-specific error codes.

## Does Not Own

- Product search UI or manual product form state.
- Inventory item models, global food nutrition models, or persistence of parsed
  nutrition values.
- Scanner receipt capture and review flows.
- Firebase AI app setup or platform-level camera permissions outside the OCR
  request boundary.

## Public Edge

Other features may consume these public Product Nutrition entry points:

- `NutritionLabelOcrRepository`
- `nutritionLabelOcrRepositoryProvider`
- `NutritionLabelOcrDraft`
- `NutritionLabelOcrResult`
- `NutritionLabelOcrStatus`
- `NutritionLabelOcrErrorCodes`

Tests may override `nutritionLabelImagePickerProvider`,
`nutritionLabelTemplateConfigClientProvider`, and
`nutritionLabelTemplateModelClientProvider` to isolate camera and model calls.

## Providers

- Repository and infrastructure client providers live in `data/` beside
  `NutritionLabelOcrRepository`.
- Domain models stay provider-free in `domain/`.
- This feature has no presentation layer and no feature-level `provider/`
  folder.

## Accepted Dependencies

Product Nutrition depends on Firebase AI, `image_picker`, and `mime` for OCR
capture, request, and MIME detection.

Current accepted cross-feature use:

- `product_search` may call the OCR repository and apply OCR drafts to manual
  product nutrition fields.

Other features should consume the public edge above instead of reaching into
private parsing helpers.

## Tests

Product Nutrition tests live under `test/features/product_nutrition/`.
