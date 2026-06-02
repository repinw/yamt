# AI Chef Feature

The `ai_chef` feature owns Firebase AI recipe generation from the cookbook
toolbar. Users can optionally include active pantry inventory, add free-form
wishes, generate a recipe, and save it as a prepared meal template.

## Owns

- AI recipe generator button (`AiChefButton`).
- Modal setup/result dialog (`AiChefDialog`).
- Loading screen with culinary quotes and rotating star icon (`AiChefLoadingView`).
- Recipe result view (`AiChefResultView`).
- Inventory prompt input formatting (`AiChefInventoryInputBuilder`).
- AI template response parsing (`AiChefRecipeResponseParser`).
- Generated cover image upload (`AiChefImageGenerator`).
- `aiChefControllerProvider`, which manages generation state.
- `aiChefRepositoryProvider`, which calls Firebase AI Logic and image
  generation.

## Does Not Own

- Recipe template persistence (owned by `inventory` repositories via
  `PreparedMealTemplatesController`).
- Inventory item lifecycle, unit conversion, or shopping list integration.
- Standard cooking flow controls.

## Public Edge

Other features may consume these public entry points:

- `AiChefButton`

## Providers

- `aiChefControllerProvider` lives in `presentation/controllers/ai_chef_controller.dart`.
- `aiChefRepositoryProvider` lives in `data/ai_chef_repository.dart`.

## Accepted Dependencies

- `core` for layout tokens, typography, and styling.
- `inventory` for `PreparedMeal`, `InventoryItem`, active pantry state via
  `InventoryItemsController`, and saving via `PreparedMealTemplatesController`.
