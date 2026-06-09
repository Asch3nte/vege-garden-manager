import 'package:flutter/material.dart';

import 'couleurs_app.dart';
import 'dimensions_app.dart';
import 'typographie_app.dart';

/// Project-specific semantic colours that have **no Material slot**.
///
/// Material's [ColorScheme] covers primary/secondary/error/surface, but the
/// « Carnet vivant » palette also has dedicated roles for *harvest/warm*,
/// *info/weather*, *success* and *warning* accents that the docs reference by
/// meaning. Exposing them as a [ThemeExtension] lets widgets read
/// `Theme.of(context).extension<AccentsCarnet>()` instead of hard-coding hexes.
@immutable
class AccentsCarnet extends ThemeExtension<AccentsCarnet> {
  /// Terracotta — soft alerts, harvests.
  final Color chaud;

  /// Bleu lin — weather, info.
  final Color info;

  /// Vert tendre — validations.
  final Color succes;

  /// Ambre — warnings.
  final Color attention;

  /// Soft separator / alternate surface.
  final Color surfaceAlternee;

  const AccentsCarnet({
    required this.chaud,
    required this.info,
    required this.succes,
    required this.attention,
    required this.surfaceAlternee,
  });

  @override
  AccentsCarnet copyWith({
    Color? chaud,
    Color? info,
    Color? succes,
    Color? attention,
    Color? surfaceAlternee,
  }) {
    return AccentsCarnet(
      chaud: chaud ?? this.chaud,
      info: info ?? this.info,
      succes: succes ?? this.succes,
      attention: attention ?? this.attention,
      surfaceAlternee: surfaceAlternee ?? this.surfaceAlternee,
    );
  }

  @override
  AccentsCarnet lerp(ThemeExtension<AccentsCarnet>? other, double t) {
    if (other is! AccentsCarnet) return this;
    return AccentsCarnet(
      chaud: Color.lerp(chaud, other.chaud, t)!,
      info: Color.lerp(info, other.info, t)!,
      succes: Color.lerp(succes, other.succes, t)!,
      attention: Color.lerp(attention, other.attention, t)!,
      surfaceAlternee: Color.lerp(surfaceAlternee, other.surfaceAlternee, t)!,
    );
  }
}

/// Builds the light and dark [ThemeData] for **« Carnet vivant »**.
///
/// Tokens come from `docs/08-design-system.md` (the validated source of truth),
/// whose light palette now reflects the Claude Design mock-ups. The "paper on a
/// table" elevation style (§6) means very diffuse, low-opacity shadows and no
/// coloured shadows — reflected here by flat card borders rather than heavy
/// elevation.
abstract final class ThemeApp {
  const ThemeApp._();

  /// Light theme (docs/08 §2).
  static ThemeData clair() {
    final scheme = const ColorScheme.light(
      primary: CouleursApp.accentPrimaireClair,
      onPrimary: CouleursApp.fondEleveClair,
      secondary: CouleursApp.accentSecondaireClair,
      onSecondary: CouleursApp.texteProncipalClair,
      surface: CouleursApp.fondPrincipalClair,
      onSurface: CouleursApp.texteProncipalClair,
      surfaceContainer: CouleursApp.fondEleveClair,
      surfaceContainerHighest: CouleursApp.surfaceAlterneeClair,
      onSurfaceVariant: CouleursApp.texteSecondaireClair,
      error: CouleursApp.erreurClair,
      onError: CouleursApp.fondEleveClair,
      outline: CouleursApp.bordureClair,
    );

    return _assembler(
      scheme: scheme,
      couleurTexte: CouleursApp.texteProncipalClair,
      accents: const AccentsCarnet(
        chaud: CouleursApp.accentChaudClair,
        info: CouleursApp.accentInfoClair,
        succes: CouleursApp.succesClair,
        attention: CouleursApp.attentionClair,
        surfaceAlternee: CouleursApp.surfaceAlterneeClair,
      ),
    );
  }

  /// Dark theme (docs/08 §3) — inhabited night blue, never black.
  static ThemeData sombre() {
    final scheme = const ColorScheme.dark(
      primary: CouleursApp.accentPrimaireSombre,
      onPrimary: CouleursApp.fondPrincipalSombre,
      secondary: CouleursApp.accentSecondaireSombre,
      onSecondary: CouleursApp.texteProncipalSombre,
      surface: CouleursApp.fondPrincipalSombre,
      onSurface: CouleursApp.texteProncipalSombre,
      surfaceContainer: CouleursApp.fondEleveSombre,
      surfaceContainerHighest: CouleursApp.surfaceAlterneeSombre,
      onSurfaceVariant: CouleursApp.texteSecondaireSombre,
      error: CouleursApp.erreurSombre,
      onError: CouleursApp.fondPrincipalSombre,
      outline: CouleursApp.bordureSombre,
    );

    return _assembler(
      scheme: scheme,
      couleurTexte: CouleursApp.texteProncipalSombre,
      accents: const AccentsCarnet(
        chaud: CouleursApp.accentChaudSombre,
        info: CouleursApp.accentInfoSombre,
        succes: CouleursApp.succesSombre,
        attention: CouleursApp.attentionSombre,
        surfaceAlternee: CouleursApp.surfaceAlterneeSombre,
      ),
    );
  }

  /// Shared assembly: applies the scheme, typography and component shapes that
  /// are identical between modes.
  static ThemeData _assembler({
    required ColorScheme scheme,
    required Color couleurTexte,
    required AccentsCarnet accents,
  }) {
    final texte = TypographieApp.construire(couleurTexte);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: texte,
      fontFamily: TypographieApp.familleCorps,
      extensions: [accents],
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: RayonsApp.brLg,
          side: BorderSide(color: scheme.outline),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondary.withValues(alpha: 0.35),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(texte.labelSmall),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: RayonsApp.brMd),
          textStyle: texte.labelLarge,
          minimumSize: const Size(0, 48), // 48dp touch target (docs/08 §8).
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
    );
  }
}
