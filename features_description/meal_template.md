# Meal Templates

## Ziel

`meal_templates` soll ein eigenes Feature unter
`lib/features/meal_templates` werden.

Es soll zwei Hauptwege geben:
- Nutzer importiert ein Rezept, zunächst nur von `chefkoch.de`
- Nutzer baut eine Mahlzeit aus dem Inventar und speichert sie als Vorlage

Wenn es sinnvoll machbar ist, sollen beide Wege langfristig im selben
`meal_template`-Modell landen.

## Import-Flow V1

1. Nutzer geht auf `Vorlagen`
2. Nutzer klickt auf `Rezept importieren`
3. Nutzer fuegt einen Chefkoch-Link oder Share-Text ein
4. Aus dem Text wird nur der echte Rezept-Link extrahiert
5. Das Rezept wird geparst
6. Es erscheint eine Review
7. Nutzer speichert die Vorlage erst nach der Review

## Importquelle V1

- Zunaechst nur `chefkoch.de`
- Andere Quellen spaeter
- Spaeter soll Import auch aus Bildern, freiem Text oder manuell moeglich sein

## Review Vor Dem Speichern

Die Review soll anzeigen:
- Bild
- Titel
- Basis-Portionen
- Zutaten
- kleinen Anleitungs-Ausschnitt, falls vorhanden

Regeln:
- Wenn das Parsing fehlschlaegt, gibt es eine harte Fehlermeldung
- Vor dem Review darf der Nutzer Link und optional Namen eingeben
- Nach der Review wird gespeichert
- Der Rezept-Link soll nach dem Review nicht mehr editierbar sein
- Wenn etwas am Link geaendert werden soll, wird der Import neu gestartet

## Gespeicherte Vorlage

Eine gespeicherte Vorlage ist sonst komplett editierbar.

Sie soll enthalten:
- Rezeptname
- Rezeptbild
- Rezeptquelle
- Basis-Portionen aus dem importierten Rezept
- Zutatenliste
- optional kurzen Anleitungs-Ausschnitt

## Vorlagen-Detailansicht

Beim Oeffnen einer Vorlage soll es geben:
- Zutaten als Tabelle
- Portionen-Einstellung
- Mengen-Skalierung auf Basis der importierten Rezept-Portionen
- Zuordnung von Zutaten zu Inventarartikeln
- Einkaufsaktion fuer fehlende Zutaten

## Zutaten-Zuordnung

Fachliche Regeln:
- Keine Zuordnung in der Review, erst in der gespeicherten Vorlage
- Einfache Auto-Match-Vorschlaege sind gut, wenn sie KISS bleiben
- Eine Rezeptzutat darf aus mehreren Inventarartikeln zusammengesetzt werden
- Zutaten duerfen offen bleiben
- Es soll einen kleinen `Ignorieren`-Button pro Zutat geben
- `Ignorieren` ist besonders fuer Dinge wie Gewuerze sinnvoll

## Fehlende Mengen

Wenn eine Zutat im Inventar vorhanden ist, aber nicht in ausreichender Menge:
- der vorhandene Teil darf uebernommen werden
- die Restmenge wird als `zu kaufen` markiert
- Teilmengen in der Einkaufsliste sind okay

## Mahlzeit Erstellen Aus Vorlage

In der Vorlagen-Ansicht soll der Nutzer `Mahlzeit erstellen` druecken koennen.

Dann gilt:
- belegte Zutaten werden aus dem Inventar genommen
- daraus wird eine Mahlzeit erzeugt
- fehlende Zutaten blockieren die Erstellung nicht
- fehlende Zutaten koennen in die Einkaufsliste uebertragen werden

Aktuelle Fachidee:
- eine unvollstaendige Mahlzeit darf erstellt werden
- sie soll aber nicht essbar sein, bis die fehlenden Zutaten aufgefuellt sind

## Aktueller MVP-Schnitt

1. Eigenes Feature `meal_templates` anlegen
2. Chefkoch-Import mit Review vor dem Speichern
3. Vorlagen-Detailansicht mit Zutaten-Tabelle und Portions-Skalierung
4. Manuelle Inventar-Zuordnung pro Zutat
5. Optional einfache Match-Vorschlaege
6. `Mahlzeit erstellen` mit Teilmengen und Einkaufslisten-Uebergabe

## Erster Umsetzungs-Slice

Der erste sinnvolle technische Slice soll noch nicht alles koennen.

Er soll nur diese Kette sauber liefern:
- Import starten
- Chefkoch-Link parsen
- Review anzeigen
- Vorlage speichern
- gespeicherte Vorlage wieder anzeigen

Noch nicht Teil dieses ersten Slices:
- Inventar-Zuordnung
- Auto-Matching
- Einkaufsliste
- Mahlzeit aus Vorlage erzeugen
- Nachfuellen einer unvollstaendigen Mahlzeit

## Screens Fuer V1

### 1. Meal Templates Page

Liste der gespeicherten Vorlagen mit Aktion:
- `Rezept importieren`

### 2. Recipe Import Sheet

Eingaben:
- Link oder Share-Text
- optional Name

Regeln:
- Quelle zunaechst nur `chefkoch.de`
- bei Fehler harte Meldung

### 3. Recipe Review Page Or Sheet

Anzeige:
- Bild
- Titel
- Basis-Portionen
- Zutaten
- kurzer Anleitungs-Ausschnitt

Aktionen:
- `Abbrechen`
- `Als Vorlage speichern`

### 4. Meal Template Detail Page

Anzeige:
- Bild
- Titel
- Quelle
- Portionen-Einstellung
- skalierte Zutaten-Tabelle

Fuer spaeter bereits sichtbar denkbar:
- kleiner `Ignorieren`-Button pro Zutat

## Datenmodell-Idee Fuer V1

Ein `meal_template` braucht voraussichtlich:
- `id`
- `name`
- `sourceType`
- `sourceUrl`
- `imageUrl`
- `basePortions`
- `createdAt`
- `updatedAt`
- `instructionsPreview`
- `ingredients`

Eine Zutat braucht voraussichtlich:
- `id`
- `name`
- `baseAmount`
- `unit`
- `isIgnored`

Hinweis:
- Die spaetere Inventar-Zuordnung lieber als eigenes Submodell halten
- Nicht jetzt schon fuer spaeter ueberdesignen

## Architektur-Idee

Neues Feature:
- `lib/features/meal_templates/data`
- `lib/features/meal_templates/domain`
- `lib/features/meal_templates/presentation`
- `lib/features/meal_templates/provider`

Bestehende Chefkoch-/Rezept-Importlogik aus `inventory` spaeter dorthin ziehen.

## Nicht-Ziele Fuer V1

Folgendes bewusst noch nicht bauen:
- mehrere Rezeptquellen
- Import aus Bild
- Import aus freiem Rezepttext
- vollstaendige Rezeptbearbeitung
- Essen-Blocklogik fuer unvollstaendige Mahlzeiten
- automatisches Auffuellen spaeter fehlender Zutaten

## Offene Punkte

- Wie genau eine unvollstaendige Mahlzeit spaeter aufgefuellt wird, ist noch
  offen
- Das schauen wir uns spaeter an

## TODO

- Diese Beschreibung aktuell halten, wenn sich Entscheidungen aendern
- Spaeter weitere Feature-Beschreibungen unter `features_description/`
  sammeln
