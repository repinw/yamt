# Kitchen Utensils Feature

Kitchen Utensils owns saved tare utensils and the kitchen-utensil management
surface.

## Owns

- Kitchen utensil domain models.
- Repository and image-url loading under `data/` and legacy `provider/`.
- Kitchen utensil controller under `presentation/controllers/`.
- Kitchen utensil mutation service under `application/`.
- Kitchen utensil page, list widgets, and cover UI.

## Does Not Own

- Cookflow session state.
- Prepared-meal storage.
- Inventory item storage.

## Public Edge

- `presentation/kitchen_utensils_page.dart` for routing.
- `presentation/controllers/kitchen_utensils_controller.dart` for reading and
  mutating saved utensils.
- `provider/kitchen_utensil_image_url_provider.dart` for resolving stored
  utensil image paths.
- `domain/kitchen_utensil.dart` for tare item data.
- `presentation/widgets/kitchen_utensil_cover.dart` for reusable utensil cover
  thumbnails.

## Providers

- Repository providers live in `data/`.
- Controller providers live in `presentation/controllers/`.
- Application services live in `application/`.
- `provider/` is legacy and still holds image helpers. Avoid new provider files
  there unless moving them would create unrelated churn.

## Accepted Dependencies

- `core` for shared primitives, image storage, and mutation queue.
- `features/auth` and `features/household` for user/household data ownership.

Current accepted consumers:

- `cooking_flow` may read utensils for tare selection.

## Tests

Kitchen-utensil tests live under `test/features/kitchen_utensils/`.
