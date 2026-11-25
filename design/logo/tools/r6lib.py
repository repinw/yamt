#!/usr/bin/env python3
"""Runde 6: Hilfen für die Nachzeichnung der Handskizze (Potrace-SVG lesen, Ringe wählen, Karomuster zeichnen).

Alle Koordinaten sind Foto-Pixel der Skizze (765 x 1024), damit Spur, Karo und Foto übereinander passen.
"""
import math, re

CROP = (100, 255, 520, 380)  # Ausschnitt des Fotos, der nachgezeichnet wird: x, y, Breite, Höhe


def parse(path_svg, k):
    """Liest ein Potrace-SVG (Ausschnitt CROP, k-fach vergrößert). Gibt je <path> eine Liste von Ringen zurück.

    Ein Ring ist eine Liste von Segmenten: ('M', p), ('L', p), ('C', c1, c2, p) in Foto-Pixeln.
    """
    s = open(path_svg).read()
    out = []
    for d in re.findall(r'<path d="([^"]*)"', s):
        toks = re.findall(r'[MmLlCcZz]|-?\d+\.?\d*', d)
        rings, ring, cur, start, cmd, i = [], None, (0.0, 0.0), (0.0, 0.0), None, 0

        def conv(p):
            return (CROP[0] + p[0] / (10.0 * k), CROP[1] + CROP[3] - p[1] / (10.0 * k))

        while i < len(toks):
            t = toks[i]
            if t in 'MmLlCcZz':
                cmd = t; i += 1
                if cmd in 'Zz':
                    rings.append(ring); ring = None; cur = start
                continue
            if cmd in 'Mm':
                x, y = float(toks[i]), float(toks[i + 1]); i += 2
                cur = (x, y) if cmd == 'M' else (cur[0] + x, cur[1] + y)
                start = cur; ring = [('M', conv(cur))]
                cmd = 'L' if cmd == 'M' else 'l'
            elif cmd in 'Ll':
                x, y = float(toks[i]), float(toks[i + 1]); i += 2
                cur = (x, y) if cmd == 'L' else (cur[0] + x, cur[1] + y)
                ring.append(('L', conv(cur)))
            elif cmd in 'Cc':
                v = [float(toks[i + j]) for j in range(6)]; i += 6
                if cmd == 'c':
                    pts = [(cur[0] + v[0], cur[1] + v[1]), (cur[0] + v[2], cur[1] + v[3]), (cur[0] + v[4], cur[1] + v[5])]
                else:
                    pts = [(v[0], v[1]), (v[2], v[3]), (v[4], v[5])]
                cur = pts[2]
                ring.append(('C', conv(pts[0]), conv(pts[1]), conv(pts[2])))
        out.append(rings)
    return out


def flat(ring, n=8):
    """Ring als Punktliste (Kurven fein unterteilt)."""
    pts, cur = [], None
    for seg in ring:
        if seg[0] in 'ML':
            cur = seg[1]; pts.append(cur)
        else:
            p0, c1, c2, p3 = cur, seg[1], seg[2], seg[3]
            for j in range(1, n + 1):
                t = j / n; u = 1 - t
                pts.append((u ** 3 * p0[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t ** 3 * p3[0],
                            u ** 3 * p0[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t ** 3 * p3[1]))
            cur = p3
    return pts


def info(ring):
    """Fläche (mit Vorzeichen), Schwerpunkt und Rahmen eines Rings."""
    p = flat(ring)
    a = cx = cy = 0.0
    for (x0, y0), (x1, y1) in zip(p, p[1:] + p[:1]):
        c = x0 * y1 - x1 * y0
        a += c; cx += (x0 + x1) * c; cy += (y0 + y1) * c
    a /= 2
    xs, ys = [q[0] for q in p], [q[1] for q in p]
    cen = (cx / (6 * a), cy / (6 * a)) if abs(a) > 1e-9 else (xs[0], ys[0])
    return a, cen, (min(xs), min(ys), max(xs), max(ys))


def d_of(rings, f=lambda p: p, nd=2):
    """SVG-Pfaddaten für eine Liste von Ringen; f bildet Foto-Pixel auf Zielkoordinaten ab."""
    def fmt(p):
        x, y = f(p)
        return f'{x:.{nd}f} {y:.{nd}f}'
    out = []
    for ring in rings:
        for seg in ring:
            if seg[0] == 'M':
                out.append('M' + fmt(seg[1]))
            elif seg[0] == 'L':
                out.append('L' + fmt(seg[1]))
            else:
                out.append('C' + ' '.join(fmt(q) for q in seg[1:]))
        out.append('Z')
    return ''.join(out)


# Karomuster, gemessen im Foto: flache Linien mit 28,3 Grad Gefälle nach rechts, steile senkrecht dazu,
# Abstand 90,5 Foto-Pixel. Die Lage ist an den Linien links und in der Mitte des Worts ausgerichtet.
GRID_ANGLE = math.radians(28.3)
GRID_STEP = 90.5
GRID_CF = 253.8   # flache Linien:  -sin*x + cos*y = GRID_CF + i*GRID_STEP
GRID_CS = 476.9   # steile Linien:   cos*x + sin*y = GRID_CS + j*GRID_STEP
GRID_WIDTH = 4.0


def grid_lines(x0, y0, x1, y1):
    """Alle Karolinien, die das Rechteck in Foto-Pixeln schneiden, als Streckenpaare (großzügig verlängert)."""
    s, c = math.sin(GRID_ANGLE), math.cos(GRID_ANGLE)
    corners = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
    L = math.hypot(x1 - x0, y1 - y0)
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    res = []
    for (nx, ny, c0, dx, dy) in ((-s, c, GRID_CF, c, s), (c, s, GRID_CS, -s, c)):
        vals = [nx * px + ny * py for px, py in corners]
        i0 = math.floor((min(vals) - c0) / GRID_STEP)
        i1 = math.ceil((max(vals) - c0) / GRID_STEP)
        for i in range(i0, i1 + 1):
            cc = c0 + i * GRID_STEP
            # Fußpunkt der Linie am Rechteckmittelpunkt
            t = cc - (nx * mx + ny * my)
            fx, fy = mx + nx * t, my + ny * t
            res.append(((fx - dx * L, fy - dy * L), (fx + dx * L, fy + dy * L)))
    return res


def squircle(cx, cy, r, n=2.8, steps=96):
    pts = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        c, s = math.cos(t), math.sin(t)
        pts.append(f"{cx + r * (abs(c) ** (2 / n)) * (1 if c >= 0 else -1):.2f},{cy + r * (abs(s) ** (2 / n)) * (1 if s >= 0 else -1):.2f}")
    return "M" + " L".join(pts) + "Z"
