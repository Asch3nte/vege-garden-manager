import 'package:flutter/material.dart';

/// Typographic scale of the **« Carnet vivant »** design system.
///
/// From `docs/08-design-system.md` §4. Titles use **Manrope**, body & UI use
/// **Inter**. The font files are not embedded yet (no `google_fonts` dependency
/// — it is not in the validated stack), so the families resolve to the platform
/// fallback until the `.ttf` assets are added to `pubspec.yaml`. Naming them now
/// keeps the call sites stable: embedding the fonts later is a pure asset change.
abstract final class TypographieApp {
  const TypographieApp._();

  /// Title font — section headers, screen titles, numbers.
  static const String familleTitres = 'Manrope';

  /// Body & UI font.
  static const String familleCorps = 'Inter';

  /// Builds the [TextTheme] for the given [couleurTexte] (text colour differs
  /// between light and dark modes, everything else is shared).
  ///
  /// Mapping to Material 3 slots:
  ///  - Display/H1/H2/H3 (Manrope) → `display*` / `headline*` / `title*`
  ///  - Body Large/Body/Body Small (Inter) → `body*`
  ///  - Caption/Button (Inter) → `label*`
  static TextTheme construire(Color couleurTexte) {
    TextStyle titre(double taille, FontWeight graisse, double hauteur) =>
        TextStyle(
          fontFamily: familleTitres,
          fontSize: taille,
          fontWeight: graisse,
          height: hauteur,
          color: couleurTexte,
        );

    TextStyle corps(double taille, FontWeight graisse, double hauteur) =>
        TextStyle(
          fontFamily: familleCorps,
          fontSize: taille,
          fontWeight: graisse,
          height: hauteur,
          color: couleurTexte,
        );

    return TextTheme(
      // Display — screen titles.
      displaySmall: titre(32, FontWeight.w700, 1.2),
      // H1 — major section.
      headlineMedium: titre(26, FontWeight.w700, 1.25),
      // H2 — card title.
      headlineSmall: titre(22, FontWeight.w600, 1.3),
      // H3 — minor titles.
      titleLarge: titre(18, FontWeight.w600, 1.35),
      // Body Large — reading body.
      bodyLarge: corps(16, FontWeight.w400, 1.5),
      // Body — standard UI.
      bodyMedium: corps(14, FontWeight.w400, 1.5),
      // Body Small — metadata.
      bodySmall: corps(13, FontWeight.w400, 1.45),
      // Caption — tags, badges.
      labelSmall: corps(12, FontWeight.w500, 1.4),
      // Button.
      labelLarge: corps(14, FontWeight.w600, 1.0),
    );
  }
}
