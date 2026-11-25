# yamt-Logo

Das Logo ist die Handskizze des Users vom 25.11.2026, als Vektor nachgezeichnet. Dieser Ordner ist die Vorlage; in der App ist davon noch nichts eingebaut.

- `final/`: die abgenommene Fassung mit allen Exporten (Android, iOS, Play, Web) und `EINBAU.md` mit den Einbauorten. Icon: ganze Schrift, fein wie gezeichnet, auf Karopapier.
- `varianten/`: alle Vektorfassungen zum späteren Wechseln:
  - `yamt-wortmarke.svg` (nur Tinte), `yamt-wortmarke-karo.svg` (auf Karopapier)
  - `yamt-icon-wort-wie-gezeichnet.svg` (abgenommen), `yamt-icon-wort.svg` (ganze Schrift, kräftiger)
  - `yamt-icon.svg` (nur das Y mit Schleife, kräftiger), `yamt-icon-wie-gezeichnet.svg` (Y, fein)
- `quelle/`: das Foto der Skizze, die Spuren und `NACHBAU.md` mit den Befehlen.
- `tools/`: die Skripte (brauchen `magick`, `potrace`, `rsvg-convert`, `python3`). `python3 tools/export_final.py varianten final` baut die Exporte neu.
