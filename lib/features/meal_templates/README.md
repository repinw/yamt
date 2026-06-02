# Meal Templates Feature

Meal templates owns the cookbook UI for browsing, importing, and reviewing
prepared-meal templates before cooking flow starts from a template.

## Owns

- Meal template list, import review, and recipe-source UI surfaces.
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
- `MealTemplateImportReviewPage`
- `RecipeSourceHost`

## Providers

Meal Templates currently owns no Riverpod providers. It composes public
providers from Inventory in presentation code.

## Accepted Dependencies

Meal Templates currently has explicit dependencies on:

- `inventory` for prepared-meal template data, inventory matching, assignment
  support, and prepared-meal creation.
- `home` for optional Home shell chrome around the templates page.
- `kitchen_utensils` for the cookbook toolbar action.
- `cooking_flow` for rendering cooking entry points on template cards.

New dependencies should be added only with a README note and should avoid new
cycles.

## Tests

Meal Templates tests live under `test/features/meal_templates/`.
