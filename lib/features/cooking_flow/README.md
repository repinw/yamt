# Cooking Flow Feature

Cooking Flow owns the guided flow for turning a prepared-meal template into one
or more saved prepared-meal containers.

## Owns

- Cookflow session snapshots and local persistence under `data/`.
- Cookflow wizard state, summary/finalize logic, instruction matching, inventory
  conflict resolution, and session mapping under `application/`.
- Cookflow pages, step widgets, local form controllers, and Riverpod UI
  controllers under `presentation/`.

## Does Not Own

- Inventory item or prepared-meal persistence.
- Shopping-list persistence.
- Kitchen utensil management.
- Product-search/manual-add flows.
- Recipe ingredient parsing.

## Public Edge

- `presentation/cooking_flow_page.dart` is the route-level page.
- `data/cooking_flow_session_local_store.dart` exposes the session snapshot used
  by template cards and app composition.
- Controllers under `presentation/controllers/` are scoped by router/tests and
  should not be assembled by sibling features.

Step widgets under `presentation/` are Cookflow internals unless a test imports
them directly.

## Providers

- Repository/store providers live in `data/`.
- Stateless use-case/service providers live in `application/`.
- UI state controllers live in `presentation/controllers/`.
- Providers use Riverpod code generation.

Main providers:

- `data/cooking_flow_session_local_store.dart`
- `application/cooking_flow_wizard_session_service.dart`
- `presentation/controllers/cooking_flow_controller.dart`
- `presentation/controllers/cooking_flow_wizard_controller.dart`
- `presentation/controllers/cooking_flow_intro_inventory_controller.dart`
- `presentation/controllers/cooking_flow_shopping_controller.dart`

## Accepted Dependencies

- `core` for routing, local preferences, shared widgets, theme tokens, and voice
  search.
- `features/inventory` for inventory/prepared-meal domain types, repositories,
  controllers, reusable prepared-meal cover UI, and inventory action color
  tokens.
- `features/recipes` for template ingredient parsing.
- `features/shoppinglist` for shopping-list item operations during intro
  shortage handling.
- `features/kitchen_utensils` for tare selection and utensil cover imagery.
- `features/product_search` for the manual-add route used when summary additions
  need a new inventory item.

Keep these dependencies at the page/controller boundary. Other features should
open `CookingFlowPage` or watch the session snapshot instead of wiring cookflow
step widgets themselves.

## Tests

- `test/features/cooking_flow/application/`
- `test/features/cooking_flow/data/`
- `test/features/cooking_flow/domain/`
- `test/features/cooking_flow/presentation/`
- `test/features/cooking_flow/presentation/controllers/`

## Migration Notes

- Riverpod controllers were moved from `application/` to
  `presentation/controllers/`.
- Legacy manual Cookflow providers were migrated to Riverpod code generation.
