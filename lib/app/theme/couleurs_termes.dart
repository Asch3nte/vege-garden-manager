import 'package:flutter/material.dart';

import '../../presentation/glossaire/type_terme_glossaire.dart';
import 'couleurs_app.dart';

/// Colour chart of the glossary term kinds (ADR-0017, D5): one colour per
/// [TypeTermeGlossaire], used by every clickable occurrence of a term across
/// the app (`TermeCliquable`, wiki links, badges, chips) so a kind is
/// recognisable at a glance.
///
/// Values reuse the « Carnet vivant » palette tokens (docs/08 §2 — no new
/// colour is invented); the dark variants come from the §3 set and must be
/// revisited when the dark mode is actually designed.
class CouleursTermes extends ThemeExtension<CouleursTermes> {
  /// Botanical families — sage green (primary accent).
  final Color famille;

  /// Diseases — soft brick (error role, never a vivid red).
  final Color maladie;

  /// Pests — earth (decorative « terre » token).
  final Color ravageur;

  /// Tools & equipment — flax blue (info role).
  final Color outil;

  /// Notions & concepts — aubergine (decorative token).
  final Color notion;

  const CouleursTermes({
    required this.famille,
    required this.maladie,
    required this.ravageur,
    required this.outil,
    required this.notion,
  });

  /// Light-mode chart (docs/08 §2 tokens).
  static const CouleursTermes clair = CouleursTermes(
    famille: CouleursApp.accentPrimaireClair,
    maladie: CouleursApp.erreurClair,
    ravageur: CouleursApp.decoTerre,
    outil: CouleursApp.accentInfoClair,
    notion: CouleursApp.decoAubergine,
  );

  /// Dark-mode chart (docs/08 §3 tokens — to revalidate with the dark design).
  static const CouleursTermes sombre = CouleursTermes(
    famille: CouleursApp.accentPrimaireSombre,
    maladie: CouleursApp.erreurSombre,
    ravageur: CouleursApp.accentChaudSombre,
    outil: CouleursApp.accentInfoSombre,
    notion: CouleursApp.decoAubergineClair,
  );

  /// The colour of a term kind.
  Color couleurDe(TypeTermeGlossaire type) => switch (type) {
        TypeTermeGlossaire.famille => famille,
        TypeTermeGlossaire.maladie => maladie,
        TypeTermeGlossaire.ravageur => ravageur,
        TypeTermeGlossaire.outil => outil,
        TypeTermeGlossaire.notion => notion,
      };

  @override
  CouleursTermes copyWith({
    Color? famille,
    Color? maladie,
    Color? ravageur,
    Color? outil,
    Color? notion,
  }) =>
      CouleursTermes(
        famille: famille ?? this.famille,
        maladie: maladie ?? this.maladie,
        ravageur: ravageur ?? this.ravageur,
        outil: outil ?? this.outil,
        notion: notion ?? this.notion,
      );

  @override
  CouleursTermes lerp(ThemeExtension<CouleursTermes>? other, double t) {
    if (other is! CouleursTermes) return this;
    return CouleursTermes(
      famille: Color.lerp(famille, other.famille, t)!,
      maladie: Color.lerp(maladie, other.maladie, t)!,
      ravageur: Color.lerp(ravageur, other.ravageur, t)!,
      outil: Color.lerp(outil, other.outil, t)!,
      notion: Color.lerp(notion, other.notion, t)!,
    );
  }
}

/// Shorthand: the term chart of the active theme.
///
/// Falls back to the light chart if the extension is missing (e.g. a bare
/// [ThemeData] in a test harness), so term rendering never crashes.
CouleursTermes couleursTermesDe(BuildContext context) =>
    Theme.of(context).extension<CouleursTermes>() ?? CouleursTermes.clair;
