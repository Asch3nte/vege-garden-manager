import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Stable hash of a family name — deterministic across runs/platforms (unlike
/// `String.hashCode`), so a family's colour and halo shape never shift.
int graineFamille(String famille) {
  var h = 0x811c9dc5;
  for (final u in famille.codeUnits) {
    h ^= u;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h;
}

/// Deterministic base colour for a family halo (hue derived from the name).
Color couleurFamille(String famille) =>
    HSLColor.fromAHSL(1, (graineFamille(famille) % 360).toDouble(), 0.5, 0.55)
        .toColor();

/// A smooth, slightly irregular ("blobby") closed contour for a family halo, in
/// **screen space**, centred on [centre] within [rayon].
///
/// Rounder than a circle yet **angle-free** (quadratic béziers). The wobble is
/// **inward only** (radius never exceeds [rayon]), so families packed without
/// overlap stay disjoint (ADR-0008). The phase is seeded on [famille] →
/// deterministic and stable under zoom.
Path cheminBlobbyFamille(Offset centre, double rayon, String famille) {
  const n = 90;
  const amplitude = 0.14; // fraction of the radius eaten inward at most
  final graine = graineFamille(famille);
  final p1 = (graine % 628) / 100.0;
  final p2 = ((graine ~/ 7) % 628) / 100.0;
  final p3 = ((graine ~/ 13) % 628) / 100.0;

  final pts = <Offset>[
    for (var k = 0; k < n; k++)
      () {
        final a = 2 * math.pi * k / n;
        final s = math.sin(a * 2 + p1) +
            0.6 * math.sin(a * 3 + p2) +
            0.45 * math.sin(a * 5 + p3);
        final w = (((s / 2.05) + 1) / 2).clamp(0.0, 1.0); // ~[0,1]
        return centre + Offset.fromDirection(a, rayon * (1 - amplitude * w));
      }(),
  ];

  // Smooth closed curve through the points (quadratic béziers via midpoints).
  final chemin = Path();
  final depart = (pts[0] + pts[n - 1]) / 2;
  chemin.moveTo(depart.dx, depart.dy);
  for (var k = 0; k < n; k++) {
    final cur = pts[k];
    final mid = (cur + pts[(k + 1) % n]) / 2;
    chemin.quadraticBezierTo(cur.dx, cur.dy, mid.dx, mid.dy);
  }
  return chemin..close();
}
