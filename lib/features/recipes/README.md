# Recipes Feature

Recipes owns parsing imported recipe ingredient text into normalized ingredient
requirements that other features can use for matching, cooking, and labels.

## Owns

- Recipe ingredient amount units and display codes in `domain/`.
- Template ingredient requirement parsing. `parseRequirement` reads the
  normalized line itself (`normalizeCookLineText`), so every caller reads a
  line alike: the recipe page, Kochmodus, plan entries, the pending
  ingredients of a prepared meal, and shopping. `parseName` reads the name of
  a Vorrat food as written: a pack size counts, a number word does not.
- The exact reading of a scaled amount (`parseIngredientExactly`,
  `ingredientQuantityText`), which the recipe page and Kochmodus share.
- Whether a recipe line counts in the nutrition (`cookLineNotCounted`).
- The reading form of a line's text (`normalizeCookLineText`: "½ Zitrone",
  "eine halbe Zitrone", "zwei Zwiebeln", "1,250 kg Mehl"), the pinch, the scoop
  (`cookTextScoop`), and the joined amount, and a line's own measure
  (`cookTextMeasure`, `cookTextStartsWithMeasure`). Callers do not normalize
  a line by hand.
- Whether an amount holds a part of a unit (`cookNeedHasPart`).
- Pending ingredient label formatting for parsed recipe requirements.
- The `TemplateIngredientParser` provider.
- Cook runs: one encrypted document per run in `households/{id}/cook_runs`,
  with lines, settlements, pots, timers and meal drafts, the pure changes to a
  run, and what running runs reserve from the Vorrat.

## Does Not Own

- Inventory item storage, consumption, or inventory amount units.
- Prepared meal persistence or mutation workflows.
- Inventory conflict resolution.
- Recipe scraping and prepared meal recipe import persistence.
- The cooking UI, and starting, pausing, finishing or discarding a run
  (`kochmodus`).

## Public Edge

Other features may consume these public Recipes entry points:

- `TemplateIngredientParser`
- `templateIngredientParserProvider`
- `TemplateIngredientRequirement`
- `TemplateIngredientUnit`

## Rules

- Create writes the whole run once. After that only update, with a change
  applied to the freshest local copy; the later device wins.
- The repository remembers its own create until the create's commit completes
  or a read shows the run: a read of no document before that builds a write on
  the run it created. Only after that does no document mean the run is gone
  (`CookRunGoneException`). A change that changes nothing writes nothing.
- Finished or discarded runs are deleted.
- Line ids stay fixed, and a line takes from each item at most once. The line
  that holds what a line lacks on the shopping list has the id
  `cookRestLineId(lineId)`.
- A line whose amount rounds to 0 for matching ("0,1 g Safran", "1/4
  Zitrone") keeps its text whole on the recipe page.
- A line's rough weight (`CookRoughWeight`) is in g or ml, never in pieces.
- A line does not count (`cookLineNotCounted`) with a pinch measure or when it
  names only salt, pepper or water. A kind word before them ("Schwarzer
  Pfeffer", "Grobes Meersalz", "Warmes Wasser") does not make it count;
  "Schwarzer Tee" counts.
- Watching skips broken runs; loading one run is strict.
- The repository's write order holds per instance, so callers keep the
  provider alive while writing.

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

Recipes must not depend on `inventory`; this keeps the shared parser usable
without a feature dependency cycle.

## Tests

Recipes tests live under `test/features/recipes/`.
