# Nachbau der Spuren (Runde 6)

Aus `handskizze_foto.jpg` (765 x 1024), Ausschnitt 520x380+100+255, Blaukanal (Karolinien sind bläulich und fallen so weg):

```bash
# ruhige Spur für alle Umrisse (Originalgröße, Potrace glättet das Pixelrauschen)
magick foto.jpg -crop 520x380+100+255 +repage -channel B -separate +channel -filter Catrom -resize 100% -blur 0x0.55 -threshold 45% -type bilevel ink_k1.pbm
potrace -s --turdsize 6 --alphamax 1.0 --opttolerance 0.4 ink_k1.pbm -o ink_k1.svg
# feine Spur nur für die Lücken der Schraffur im A (vierfach, dunklere Schwelle, damit die schmalen Lücken ihre Breite behalten)
magick foto.jpg -crop 520x380+100+255 +repage -channel B -separate +channel -filter Lanczos -resize 400% -blur 0x1.2 -threshold 34% -type bilevel ink_fein.pbm
potrace -s --turdsize 10 --alphamax 1.0 --opttolerance 0.5 ink_fein.pbm -o ink_fein.svg
python3 ../tools/build_r6.py . out 7 28 3
```
