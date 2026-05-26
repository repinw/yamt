# Shopping List Feature

Shopping List owns user grocery-list storage, list mutations, and the shopping
list page.

## Owns

- Shopping-list item domain models.
- Firestore/local repository implementations under `data/`.
- List mutation and normalization helpers under `application/`.
- Shopping-list page, widgets, and controller under `presentation/`.

## Does Not Own

- Inventory stock persistence.
- Recipe or cookflow ingredient parsing.
- Household membership workflows.

## Public Edge

- `presentation/shopping_list_page.dart` for routing.
- `presentation/controllers/shopping_list_controller.dart` for existing feature
  integrations that add or resolve shopping-list items.
- `application/shopping_list_operations.dart` for value normalization helpers.
- `domain/shopping_list_item.dart` for list item data.

## Providers

- Repository providers live in `data/`.
- Controller providers live in `presentation/controllers/`.

## Accepted Dependencies

- `core` for mutation queue and app primitives.
- `features/auth` and `features/household` for user/household data ownership.

Current accepted consumers:

- `inventory` may add items from inventory rows.
- `cooking_flow` may add shortage labels and resolve used shopping-list items.

## Tests

Shopping-list tests live under `test/features/shoppinglist/`.
