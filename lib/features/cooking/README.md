# Cooking

## Purpose

The new cooking flow (Kochmodus rebuild, #935 and later slices): cooking a
recipe from the Vorrat into a Vorrat meal. It replaces the cooking parts of
`cookbook_new` slice by slice; until then it is reached only through a long
press on the ingredients title of the recipe page.

## Owns

- The cooking of one recipe (`CookSession`): its portions, how each line is
  settled (assigned to Vorrat items, left out), the pot and the step.
- The one rule that suggests Vorrat items for a recipe line (`suggest`).
- "In Vorrat": building the cooked meal from the assigned items and writing
  it with its stock (`CookFinishService`).
- The cooking page and its steps: Rezept, Einkauf, Kochen, Portionieren.

## Does Not Own

- Recipe storage: slice 1 reads the Kochbuch templates (`inventory`) read
  only.
- Vorrat items, Vorrat meals and the batch that writes them (`inventory`).
- Saved pots (`kitchen_utensils`).

## Rules

- The app never assigns a line by itself. A suggestion counts only after
  the cook's ✓ or pick; then the line is `LineAssigned` with its takes.
- Before "In Vorrat" every line is assigned or left out.
- The cooking lives only while its page is open (slice 1); nothing is
  reserved in Firestore. Within one cooking, an item one line takes is not
  offered again to another.
- A suggestion takes the items the recipe saved for the line, else the best
  name matches; one item that supplies the line alone comes first (opened
  packs, then the oldest), else they are combined in that order.
- "In Vorrat" reads the Vorrat again and writes the stock and the meal in
  one batch; when an item lacks nutrition or holds too little, nothing is
  written.
