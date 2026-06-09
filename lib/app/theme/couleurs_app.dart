import 'package:flutter/painting.dart';

/// Raw colour tokens of the **« Carnet vivant »** design system.
///
/// Values come straight from the validated design system in
/// `docs/08-design-system.md` (§2 light, §3 dark), which is the source of truth
/// for the project. The **light** roles (§2.1) and the decorative palette (§2.2)
/// reflect the validated Claude Design mock-ups (`vege-garden-export/`,
/// `bg-directions.css`). The **dark** roles still come from the original CAHIER
/// §4.1 — the mock-ups did not redefine a dark mode.
///
/// These are intentionally *semantic* roles, not Material slots — the mapping to
/// a Flutter [ColorScheme] happens in [ThemeApp]. Keeping the roles here lets
/// widgets that need a project-specific colour (e.g. the warm "harvest" accent,
/// which has no Material equivalent) reach for it by meaning rather than by
/// guessing a hex value.
abstract final class CouleursApp {
  const CouleursApp._();

  // ── Light mode — semantic roles (docs/08 §2.1) ───────────────────────────

  /// Crème lin — application background (`--c-bg`).
  static const Color fondPrincipalClair = Color(0xFFF6F2E9);

  /// Blanc cassé — cards, modals (`--c-surface`).
  static const Color fondEleveClair = Color(0xFFFFFDF7);

  /// Beige doux — alternate sections, soft separators (`--c-alt`).
  static const Color surfaceAlterneeClair = Color(0xFFECE6D6);

  /// Anthracite végétal — titles, body text (`--c-ink`).
  static const Color texteProncipalClair = Color(0xFF241C28);

  /// Taupe — captions, metadata (`--c-ink-2`).
  static const Color texteSecondaireClair = Color(0xFF6E6357);

  /// Vert sauge profond — buttons, links, primary actions (`--c-primary`).
  static const Color accentPrimaireClair = Color(0xFF2F7D4F);

  /// Vert mousse clair — hover, badges (`--c-primary-2`).
  static const Color accentSecondaireClair = Color(0xFF8FCB8E);

  /// Terracotta doux — soft alerts, harvests (`--c-warm`).
  static const Color accentChaudClair = Color(0xFFD6573D);

  /// Bleu lin — weather, info (`--c-info`).
  static const Color accentInfoClair = Color(0xFF4E89B0);

  /// Vert tendre — validations (`--c-success`).
  static const Color succesClair = Color(0xFF4CA464);

  /// Ambre doux — warnings (`--c-attention`).
  static const Color attentionClair = Color(0xFFE0A82E);

  /// Brique douce — errors, never a vivid red (`--c-error`).
  static const Color erreurClair = Color(0xFFB0463C);

  /// Beige ombré — strokes, separators (`--c-border`).
  static const Color bordureClair = Color(0xFFDBD2C0);

  // ── Decorative palette (docs/08 §2.2) ────────────────────────────────────
  // Non-semantic: tile gradients, vegetal separators, organic blobs/arches,
  // illustrations. Never use these to convey a state — that's the §2.1 roles.

  /// Vert moyen — tile gradients, vegetal accents (`--c-green-mid`).
  static const Color decoVertMoyen = Color(0xFF4FA06A);

  /// Vert profond — immersive arches/headers, gradients (`--c-green-deep`).
  static const Color decoVertProfond = Color(0xFF1E4D33);

  /// Aubergine — vegetal separators, harvests, decor (`--c-aubergine`).
  static const Color decoAubergine = Color(0xFF6A3D5B);

  /// Aubergine clair — light aubergine variant (`--c-aubergine-2`).
  static const Color decoAubergineClair = Color(0xFFB98AAC);

  /// Aubergine profond — occasional dark fills, e.g. chips (`--c-aubergine-deep`).
  static const Color decoAubergineProfond = Color(0xFF2C1A27);

  /// Bordeaux — tile gradients, warm accents (`--c-bordeaux`).
  static const Color decoBordeaux = Color(0xFF9B3B43);

  /// Terre — "earth" decor, climbers (`--c-terre`).
  static const Color decoTerre = Color(0xFFA9744B);

  /// Ocre — warm decor; equals the Attention semantic role (`--c-ocre`).
  static const Color decoOcre = Color(0xFFE0A82E);

  // ── Dark mode (docs/08 §3) ───────────────────────────────────────────────
  // Not re-validated by the Claude Design mock-ups (light-only). From CAHIER
  // §4.1; revisit when a dark mode is actually designed.

  /// Bleu nuit profond — application background (inhabited night blue, never black).
  static const Color fondPrincipalSombre = Color(0xFF161D26);

  /// Bleu nuit doux — cards, modals.
  static const Color fondEleveSombre = Color(0xFF1E2733);

  /// Bleu nuit clair — alternate sections.
  static const Color surfaceAlterneeSombre = Color(0xFF26303D);

  /// Crème douce — titles, body text.
  static const Color texteProncipalSombre = Color(0xFFEAE6DC);

  /// Gris bleuté — captions, metadata.
  static const Color texteSecondaireSombre = Color(0xFF9AA3AE);

  /// Vert sauge lumineux — primary actions.
  static const Color accentPrimaireSombre = Color(0xFF7FB088);

  /// Vert mousse — hover, badges.
  static const Color accentSecondaireSombre = Color(0xFF5C8A6A);

  /// Terracotta clair — soft alerts, harvests.
  static const Color accentChaudSombre = Color(0xFFD89072);

  /// Bleu lin clair — weather, info.
  static const Color accentInfoSombre = Color(0xFF8FA8C7);

  /// Vert tendre clair — validations.
  static const Color succesSombre = Color(0xFF8BC487);

  /// Ambre clair — warnings.
  static const Color attentionSombre = Color(0xFFE8B860);

  /// Brique claire — errors.
  static const Color erreurSombre = Color(0xFFD17560);

  /// Bleu nuit clair — strokes, separators.
  static const Color bordureSombre = Color(0xFF2F3A48);
}
