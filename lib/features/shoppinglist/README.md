# Shopping List

## Purpose

Shopping List keeps the household's grocery list: what to buy and how many,
saved favorites, and products that come back on a schedule.

## Owns

- Shopping list items with their favorite and recurrence settings, stored
  encrypted with the household key.
- List mutations: adding and merging products, quantities, crossing off,
  reverting an addition, and the calendar recurrence rules.
- Suggestion filtering and the visible list sections.
- The shopping list page, its widgets, and its controller.

## Does Not Own

- Inventory stock and the purchase interpretation of a list entry.
- Recipe and cooking ingredient parsing.
- Household membership and the household key.

## Public UI

- `ShoppingListPage` with its `suggestionsSection` slot. Inventory fills the
  slot with its own suggestions and composes the finished page.
- `ShoppingListSuggestions` renders `ShoppingSuggestion` values and hides
  products that are already on the list.
- `ShoppingListPlanNeeds` renders the "Für deinen Plan" block from
  `ShoppingPlanNeedGroup` values, with one add button per food, and an error
  line with a retry when the needs fail to load. `groupShoppingPlanNeeds`
  (application) groups `ShoppingPlanNeed` values by day and meal and drops
  foods that are already on the list.

## Rules

- Removing or clearing a saved product archives its entry and keeps the
  favorite and the schedule. Re-adding reuses the same entry and never
  duplicates an active item.
- Recurrence uses a local calendar interval of 1 to 365 days, a quantity of 1
  to 999, and a first due date. Due entries reactivate once at load, on
  resume, or on the page's minute tick. Missed intervals advance to the next
  future date without a backlog. Active quantities stay unchanged.
- Configuring a schedule and applying it when already due is one serialized
  save. A failed save rolls both back for a later retry. Widgets only submit
  the settings; activation does not depend on the widget staying mounted.
- Every save replaces the whole list in one serialized write. While the user
  is signed out or the household key is not ready, reads return no items and
  writes fail.
