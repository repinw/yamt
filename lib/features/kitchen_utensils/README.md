# Kitchen Utensils Feature

## Purpose

Kitchen Utensils owns the saved tare utensils (pots, boxes, bowls with their
empty weight and photo) and the page that manages them.

## Owns

- Kitchen utensil models and their sort and validation rules.
- Utensil persistence and utensil photos in Storage.
- The read-only utensil list and image URLs that other features watch.
- The utensil management page, its edit flow, and its controller.

## Does Not Own

- The pot weight on "Gekocht" that picks a utensil.
- Prepared-meal and inventory item storage.

## Public UI

- `KitchenUtensilCover`: square utensil thumbnail.
- `KitchenUtensilsButton`: opens the utensil management page.
- `KitchenUtensilEditFlow` (`add`): adds a utensil and returns its id, or
  `null` when the cook cancels or the save fails. The sheet says
  "Utensil hinzufügen" unless the caller passes a `title`; the Töpfe step of
  Kochmodus passes "Topf oder Pfanne hinzufügen" and chooses the new pot at
  once. The button of a new utensil says "Hinzufügen", and a helper under the
  weight says how to find it ("Leer, ohne Deckel. …").
