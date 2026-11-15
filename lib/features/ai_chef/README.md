# AI Chef

## Purpose

Asks for a recipe idea and loads it: the setup sheet, the wait, and the idea
with its picture. It saves nothing; the cookbook shows and saves the idea.

## Owns

- The sheet that asks for an idea (`AiChefSheet`) and its three setup rows
  (`AiChefSetupView`, no title): "Vorrat zuerst" with the "Unbedingt rein"
  chips (`AiChefMustUseChips`), the wish pills and the "Bloß nicht" pills
  (both `AiChefPillRow`). What the cook set up for one idea lives in
  `AiChefSetupDraft` (not stored). Errors of the list and the picks show in
  the sheet, not as snack bars under it. While the idea loads it shows a
  calm wait. A failed idea says so and offers "Erneut versuchen". Closing the sheet
  drops the idea.
- The idea (`AiChefRecipeIdea`, a `PreparedMeal` and the prompt for its
  picture) and the call that makes it (`aiChefRepositoryProvider`,
  `loadRecipeIdea`). It reads the server template `recipe-idea-template`: the
  values of each ingredient (text, amount, unit, kcal, protein, carbs, fat).
  The recipe's totals are the sums of its ingredients; one portion is that
  sum divided by the portions. The answer is read strictly
  (`AiChefRecipeResponseParser`); a broken answer is a failed idea. The
  template for released app versions stays on the server; this code does not
  use it.
- The Vorrat foods that the prompt names, if the cook wants them, and the
  oldest-first order with days in stock (`AiChefInventoryInputBuilder`).
- "Unbedingt rein": the pick sheet (`AiChefMustUseSheet`, opened by
  `pickAiChefMustUseItems` with `AiChefController.loadPickableItems`) lists
  the Vorrat oldest first with its age. A Vorrat that cannot be read fails
  an idea with picks instead of dropping them. The
  controller gets the picked ids and looks them up in the Vorrat it reads
  for the request, so a pick eaten since then is left out. They go to the
  template as `must_use_ingredients` (one per line in the Vorrat form, left
  out when empty), only with the Vorrat on.
- The per-user "Bloß nicht" list (`AiChefExclusions`,
  `aiChefExclusionsRepositoryProvider`, `aiChefExclusionsControllerProvider`),
  stored encrypted with the user data key in
  `users/{uid}/ai_chef_settings/exclusions`, so it follows the user to every
  device. Every request sends it as `excluded_ingredients` (one per line,
  left out when empty).
- The picture of an idea (`aiChefImageGeneratorProvider`, one call per idea,
  no retry) and its upload (`saveCover` of the repository).
- `aiChefControllerProvider`, the state of one idea request.

## Does Not Own

- Showing the idea as a recipe, saving it, and putting the picture on the
  saved recipe (`cookbook_new`).
- Recipe persistence and the estimate type (`inventory`).

## Public UI

- `AiChefSheet.show(context)`: returns the idea, or `null` when the cook
  closes the sheet first. `cookbook_new` opens it from "Neues Rezept".
