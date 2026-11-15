# AI Chef

## Purpose

Asks for a recipe idea and loads it: the setup sheet, the wait, and the idea
with its picture. It saves nothing; the cookbook shows and saves the idea.

## Owns

- The sheet that asks for an idea (`AiChefSheet`): "Worauf hast du Lust?",
  the Vorrat switch, and the wishes. While the idea loads it shows a calm
  wait. A failed idea says so and offers "Erneut versuchen". Closing the sheet
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
- The Vorrat foods that the prompt names, if the cook wants them
  (`AiChefInventoryInputBuilder`).
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
