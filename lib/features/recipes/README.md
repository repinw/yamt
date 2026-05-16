# Recipes Feature

Recipes owns parsing imported recipe ingredient text into normalized ingredient
requirements that other features can use for matching, cooking, and labels.

## Owns

- Recipe ingredient amount units and display codes in `domain/`.
- Template ingredient requirement parsing.
- Pending ingredient label formatting for parsed recipe requirements.
- The `TemplateIngredientParser` provider.

## Does Not Own

- Inventory item storage, consumption, or inventory amount units.
- Prepared meal persistence or mutation workflows.
- Cooking-flow session state and inventory conflict resolution.
- Recipe scraping and prepared meal recipe import persistence.

## Public Edge

Other features may consume these public Recipes entry points:

- `TemplateIngredientParser`
- `templateIngredientParserProvider`
- `TemplateIngredientRequirement`
- `TemplateIngredientUnit`

## Providers

- Application providers live in `application/` beside their implementation.
- Domain-free parsing helpers stay provider-free unless they need app
  composition or test overrides.
- Recipes does not use a feature-level `provider/` folder.

## Accepted Dependencies

Recipes depends on `core` for flexible decimal parsing and on Riverpod for the
parser provider. Pure recipe ingredient value objects stay in `domain/`.

Current accepted cross-feature use:

- `inventory` may parse recipe ingredients and map recipe units to inventory
  amount units at the inventory boundary.
- `meal_templates` may parse and display ingredient requirements.
- `cooking_flow` may parse recipe requirements for cooking instructions,
  inventory checks, and summary labels.

Recipes must not depend on `inventory`; this keeps the shared parser usable
without a feature dependency cycle.

## Tests

Recipes tests live under `test/features/recipes/`.
