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

- Cookflow session state and the tare picker of the cooking flow.
- Prepared-meal and inventory item storage.

## Public UI

- `KitchenUtensilCover`: square utensil thumbnail.
- `KitchenUtensilsButton`: opens the utensil management page.
