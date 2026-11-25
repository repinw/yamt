# yamt-Logo

Das Logo ist die Handskizze des Users vom 25.11.2026, als Vektor nachgezeichnet. Dieser Ordner ist die Vorlage.

- `final/`: die abgenommene Fassung mit allen Exporten (Android, iOS, Play, Web) und `EINBAU.md` mit den Einbauorten. Icon: ganze Schrift, fein wie gezeichnet, auf Karopapier.
- `varianten/`: alle Vektorfassungen zum späteren Wechseln:
  - `yamt-wortmarke.svg` (nur Tinte), `yamt-wortmarke-karo.svg` (auf Karopapier)
  - `yamt-icon-wort-wie-gezeichnet.svg` (abgenommen), `yamt-icon-wort.svg` (ganze Schrift, kräftiger)
  - `yamt-icon.svg` (nur das Y mit Schleife, kräftiger), `yamt-icon-wie-gezeichnet.svg` (Y, fein)
- `quelle/`: das Foto der Skizze, die Spuren und `NACHBAU.md` mit den Befehlen.
- `tools/`: die Skripte (brauchen `magick`, `potrace`, `rsvg-convert`, `python3`). `python3 tools/export_final.py varianten final` baut die Exporte neu.

Eingebaut ist seit dem 25.11.2026 die feine Fassung (App-Icon und Startbild, Android und iOS). Der User fand sie auf dem Handy sehr unauffällig, lässt sie aber vorerst so. `varianten/auffaelliger/` hält die geprüften kräftigeren Fassungen (Strich 8 bis 10 Foto-Pixel über `tools/icon_wort.py`, dann Farben getauscht) mit Vergleichsbildern. Befund: Bekommt das Y eine eigene Farbe, liest man den Rest als das Wort „AMT“; also nur einfarbig.

Seit dem 25.11.2026 abends hat das Icon einen limettenfarbenen Rahmen (`#B6F23A`), vom User gewählt: erst 3 dp (Radius 31), dann breiter mit 5 dp (Radius 29, eingebaut). Neu bauen: `python3 tools/export_final.py varianten final yamt-icon-wort-wie-gezeichnet-r29.svg 5`. Ohne die letzten zwei Angaben entsteht die Fassung ohne Rahmen.
