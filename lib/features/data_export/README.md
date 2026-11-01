# Data Export Feature

## Purpose

Data Export writes the food, goals, weight, and TDEE of a period as files
that the user passes on through the share sheet: text for an AI, a PDF
report, and an Excel table. The data is end-to-end encrypted, so the files
are written on the device.

## Owns

- The export page with the purpose (Meine KI, Ernährungsberater, Für mich)
  and the period (current goal, all data, one or more goals, last days,
  calendar; nothing before the first goal), with Teilen, Kopieren (AI
  text to the clipboard), and Speichern (Für mich, system save dialog).
- The export report read model, built from the calorie entries, goal
  settings, weights, TDEE, and the parts of the day.
- The text (Markdown inside), PDF, and `.xlsx` writers and the hand-off
  to the share sheet, the save dialog, and the clipboard.

## Does Not Own

- Calorie entries, goals, the learned TDEE (Calories), weights (Health), the
  parts of the day (Diary), and the goal periods (Progress). It only reads
  them.
- The `.xlsx` encoder, which lives in `lib/core/utils/`.
- The menu entries that open the page (Home, Settings).
