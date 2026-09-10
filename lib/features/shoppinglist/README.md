# Shopping List Feature

Shopping List owns user grocery-list storage, list mutations, and the shopping
list page.

## Owns

- Shopping-list items, favorites and recurring-item settings.
- Firestore/local repository implementations under `data/`.
- Pure mutation, normalization and calendar recurrence rules under `domain/`.
- Recommendation filtering and visible list sections under `application/`.
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
- Application providers use `riverpod_annotation` and generated parts.

## Recommendations and Saved Products

- `domain/shopping_suggestion.dart` is the public, inventory-independent input
  model. `shoppingSuggestionSourceProvider` and `shoppingSuggestionRetryProvider`
  in `application/shopping_suggestions.dart` are scoped injection points.
- The generated `shoppingSuggestionsProvider` removes already-listed products
  and limits the visible result to six. Widgets display the resulting state;
  they do not read inventory repositories or aggregate consumption/purchases.
- Inventory owns stock/purchase interpretation and exposes the finished
  `InventoryShoppingListPage`. The router composes that page; dependency
  direction remains `inventory -> shoppinglist`.
- Favorites and schedules are stored on existing `shopping_list_items` documents.
  Missing fields in older documents default to an ordinary list entry.
- Removing or clearing a saved product archives its list entry, retaining the
  favorite/schedule. Re-adding reuses the same document and does not duplicate
  an already active item.
- Recurrence uses a local calendar interval (1–365 days), quantity (1–999), and
  first due date. Due records reactivate once at load/resume or the page's
  minute tick. Missed intervals advance to the next future date without adding
  a backlog. Existing active quantities remain unchanged.
- Reactivation and due-date advancement share the same serialized persistence
  operation. A failed save rolls both back for a later retry. This is an app
  feature, not a background delivery/order service while the app is closed.

## Accepted Dependencies

- `core` for mutation queue and app primitives.
- `features/auth` and `features/household` for user/household data ownership.

Current accepted consumers:

- `inventory` may add items from inventory rows.
- `cooking_flow` may add shortage labels and resolve used shopping-list items.

## Tests

Shopping-list tests live under `test/features/shoppinglist/`, including legacy
JSON, schedule advancement, save rollback, favorite reuse, form validation,
recommendation insertion, and narrow-screen rendering. Purchase/stock rules and
the inventory integration are tested under `test/features/inventory/`.

### Schedule configuration and UI composition

`ShoppingListController.setSchedule` configures the schedule and applies it when
already due in a single serialized save. Widgets only submit the settings;
activation does not depend on the widget remaining mounted. Failed persistence
rolls back both the settings and activation together.

The content and schedule dialog use component folders under
`presentation/widgets/shopping_list_content/` and
`presentation/widgets/shopping_list_schedule_dialog/`. Their section, empty-state,
and form helpers remain alongside the owning widget; imports target concrete files.
