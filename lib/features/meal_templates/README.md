# Meal Templates Feature

Meal templates owns the cookbook UI for browsing, importing, reviewing, and
matching prepared-meal templates before creating inventory-backed meals.

## Owns

- Meal template list, detail, import review, and recipe-source UI surfaces.
- Template ingredient assignment state inside the detail page.
- Presentation helpers for scaling recipe ingredient labels and shopping-list
  remainder labels.
- Import-review argument models used by meal-template routes.

## Does Not Own

- Prepared meal persistence, template repositories, or mutation workflows.
- Inventory item storage, matching domain models, or inventory consumption.
- Recipe ingredient parsing rules.
- Shopping-list persistence.
- Cooking-flow session state.

## Public Edge

Other features may consume these public Meal Templates entry points:

- `MealTemplatesPage`
- `MealTemplateDetailPage`
- `MealTemplateImportReviewPage`
- `RecipeSourceHost`

Internal detail widgets and helpers live under
`presentation/widgets/meal_template_detail/` for maintainability, but they are
not public cross-feature composition surfaces.

## Providers

Meal Templates currently owns no Riverpod providers. It composes public
providers from Inventory, Recipes, and Shopping List in presentation code.

## Accepted Dependencies

Meal Templates currently has explicit dependencies on:

- `inventory` for prepared-meal template data, inventory matching, assignment
  support, and prepared-meal creation.
- `recipes` for template ingredient parsing and normalized recipe requirement
  labels.
- `shoppinglist` for adding missing recipe ingredients to the shopping list.
- `home` for optional Home shell chrome around the templates page.
- `kitchen_utensils` for the cookbook toolbar action.
- `cooking_flow` for rendering cooking entry points on template cards.

New dependencies should be added only with a README note and should avoid new
cycles.

## Tests

Meal Templates tests live under `test/features/meal_templates/`.

## Migration Notes

- The meal-template detail page was split from hand-written `part` files into
  a component folder with `meal_template_detail.dart` as the main widget file.
