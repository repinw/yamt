#!/usr/bin/env python3
"""Runde 6: Karolinien des Fotos auf einzelnen Abtastzeilen und -spalten finden (für die Entzerrung).

Aufruf: gitter.py <foto.ppm> h <y> | v <x>
Gibt die Mitten aller Karolinien auf der Zeile (h) oder Spalte (v) aus, auf Zehntel Pixel.
"""
import sys

def load(path):
    d = open(path, 'rb').read()
    # P6-Kopf lesen
    parts, i = [], 0
    while len(parts) < 4:
        while d[i:i + 1].isspace():
            i += 1
        j = i
        while not d[j:j + 1].isspace():
            j += 1
        parts.append(d[i:j]); i = j
    w, h = int(parts[1]), int(parts[2])
    return w, h, d[i + 1:]

W, H, PIX = load(sys.argv[1])

def lum(x, y):
    o = (y * W + x) * 3
    return 0.299 * PIX[o] + 0.587 * PIX[o + 1] + 0.114 * PIX[o + 2]

def profile(kind, pos):
    if kind == 'h':
        return [sum(lum(x, pos + d) for d in (-1, 0, 1)) / 3 for x in range(W)]
    return [sum(lum(pos + d, y) for d in (-1, 0, 1)) / 3 for y in range(H)]

def crossings(p):
    n = len(p)
    # Papierhelligkeit als gleitendes Maximum, Linien als Senken
    res, i = [], 0
    while i < n:
        lo, hi = max(0, i - 25), min(n, i + 26)
        paper = sorted(p[lo:hi])[int((hi - lo) * 0.8)]
        if p[i] < paper - 14:
            j = i
            while j < n and p[j] < sorted(p[max(0, j - 25):min(n, j + 26)])[int((min(n, j + 26) - max(0, j - 25)) * 0.8)] - 14:
                j += 1
            seg = range(i, j)
            mn = min(p[k] for k in seg)
            wts = [(paper - p[k]) for k in seg]
            c = sum(k * wt for k, wt in zip(seg, wts)) / sum(wts)
            res.append((round(c, 1), j - i, round(mn)))
            i = j
        else:
            i += 1
    return res

if __name__ == '__main__':
    kind, pos = sys.argv[2], int(sys.argv[3])
    for c in crossings(profile(kind, pos)):
        print(*c)
