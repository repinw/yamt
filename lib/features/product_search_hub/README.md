Beschreibung
Es soll eine einheitliche Produktsuche sein.
Sie bietet normale Suche, suche über Barcode, AI erstellung, eigenes Produkt erstellen

Zielbild:

- Aufruf aus dem Tagebuch startet den Hub im Eat-Flow-Kontext.
- Aufruf aus dem Vorrat startet den Hub im Vorrats-Kontext.
- Suche, Barcode, KI, zuletzt ausgewählt und eigener Artikel nutzen denselben
  Hub und denselben nachgelagerten Editor-Schritt.
- Aus Vorrat, Mahlzeit und Beleg sind Diary-Quellen für später.

Aktuelle Migrationsstufe:

- "Zuletzt ausgewählt" nutzt die bestehenden letzten manuellen Produkte aus
  `inventory` über `manualProductRecentItemsServiceProvider`.
- Die Suchleiste nutzt die bestehende OFF-Produktsuche aus `inventory` über
  `offProductSearchRepositoryProvider` auf einer eigenen Suchseite mit
  Debounce und Deduplizierung wie `product_search`. Die Oberfläche nutzt die
  gemeinsame Vorrats-Suchleiste `TextVoiceSearchBar` inklusive Voice-Search.
- Die Hub-Seite zeigt nur den Such-Einstieg. Die echte Suchleiste lebt in
  `ProductSearchHubSearchPage` und wird per Hero-Animation geöffnet und
  geschlossen.
- Wird ein Produkt aus Suche, Barcode, KI, eigener Erstellung oder zuletzt
  ausgewählt gewählt, öffnet sich zuerst der bestehende manuelle Editor aus
  `product_search`.
- Im Vorrats-Kontext speichert der Hub bearbeitete Produkte direkt in den
  Vorrat und zeigt sie zusätzlich im Overlay an.
- Im Tagebuch-Kontext speichert der Hub bearbeitete Produkte in den Vorrat und
  führt anschließend den Eat Flow aus. Aus Vorrat, Mahlzeit und Beleg bleiben
  zunächst sichtbare, deaktivierte Platzhalter für spätere Diary-Quellen.
- Für alte reine Auswahl-Aufrufer kann der Hub im Selection-Modus geöffnet
  werden. Dann wird der bearbeitete Editor-Result zurückgegeben und nichts
  gespeichert.

Modus-Regeln:

- Inventory-Modus:
  Titel ist "Zum Vorrat hinzufügen"; Aus Vorrat, Mahlzeit und Beleg sind
  ausgeblendet; Save-Result wird zum Vorrat hinzugefügt.
- Diary-Modus:
  Titel ist "Lebensmittel essen"; Aus Vorrat, Mahlzeit und Beleg sind sichtbar
  aber deaktiviert; Save-Result läuft durch den Eat Flow.
- Selection-Modus:
  Titel ist "Produkt hinzufügen"; Aus Vorrat, Mahlzeit und Beleg sind
  ausgeblendet; der bearbeitete Result wird an den Aufrufer zurückgegeben.

Barcode:

- Der Hub verwendet die bestehende Scanner-Oberfläche aus `inventory`.
- Inventory-Modus zeigt keine expliziten Kandidaten-Aktionsbuttons; Auswahl
  bedeutet Vorrat.
- Diary-Modus zeigt Eat-only-Kandidatenaktionen.
- Bei vollständigen Nährwerten übernimmt der Hub die direkte Eat-Optimierung
  aus `product_search`.
- Bei fehlenden Eat-Nährwerten öffnet der Hub den Editor mit Hinweis, damit
  die Werte vor dem Essen ergänzt werden können.

Altes Manual Add:

- `InventoryManualAddPage` und `/home/inventory/manual-add` wurden nach
  Parität entfernt.
- Der Hub ersetzt den alten Einstieg für Launcher, Suche, Barcode, KI,
  Voice-Search, zuletzt ausgewählte Produkte, Vorrat-Speichern,
  Missing-Barcode-Dialog und Eat-Flow-Kontext.
