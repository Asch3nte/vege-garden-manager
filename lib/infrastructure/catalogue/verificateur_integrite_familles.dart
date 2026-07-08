import '../../domain/entities/famille_botanique.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/value_objects/precedent_cultural.dart';
import 'famille_botanique_cache.dart';

/// A single referential-integrity problem found between the plant catalogue and
/// the family reference (ADR-0006).
class ProblemeIntegriteFamille {
  /// Offending species id.
  final String espece;

  /// Human-readable reason.
  final String raison;

  const ProblemeIntegriteFamille(this.espece, this.raison);

  @override
  String toString() => '$espece: $raison';
}

/// Cross-checks that the plant catalogue and the family reference are coherent
/// (ADR-0006, Décisions 1 & 3):
///
/// 1. **Coverage** — the family of every species (the normalized
///    `famille_botanique`) must have a loaded family sheet.
/// 2. **Coherence** — when a species also declares `rotation.famille`, it must
///    equal that normalized key.
/// 3. **Precedents** — every *family* cultural precedent (rotation avancée,
///    Lot 2) must resolve to a loaded family sheet. Functional-group precedents
///    ([GroupeCultural]) carry no family reference and are always valid.
///
/// Pure and non-fatal: it *reports* problems (it never throws), so callers can
/// log them without aborting the load.
class VerificateurIntegriteFamilles {
  const VerificateurIntegriteFamilles();

  /// Returns every problem found for [especes] against [familles] (empty when
  /// the two sets are coherent).
  List<ProblemeIntegriteFamille> verifier(
    Iterable<FichePlante> especes,
    FamilleBotaniqueCache familles,
  ) {
    final problemes = <ProblemeIntegriteFamille>[];
    for (final espece in especes) {
      final cle = FamilleBotanique.normaliserCle(espece.familleBotanique);
      if (familles.parId(cle) == null) {
        problemes.add(ProblemeIntegriteFamille(espece.id,
            'no family sheet for "${espece.familleBotanique}" (expected id "$cle")'));
      }
      final rotation = espece.rotationFamille;
      if (rotation != null && rotation != cle) {
        problemes.add(ProblemeIntegriteFamille(espece.id,
            'rotation.famille "$rotation" ≠ normalized famille_botanique "$cle"'));
      }
      _verifierPrecedents(
          espece, familles, problemes, espece.precedentsFavorables, 'favorable');
      _verifierPrecedents(espece, familles, problemes,
          espece.precedentsDefavorables, 'défavorable');
    }
    return problemes;
  }

  /// Reports any *family* precedent in [precedents] whose slug has no loaded
  /// family sheet. Group precedents are skipped (no family to resolve).
  void _verifierPrecedents(
    FichePlante espece,
    FamilleBotaniqueCache familles,
    List<ProblemeIntegriteFamille> problemes,
    Set<PrecedentCultural> precedents,
    String sens,
  ) {
    for (final p in precedents) {
      final slug = p.familleSlug;
      if (slug != null && familles.parId(slug) == null) {
        problemes.add(ProblemeIntegriteFamille(espece.id,
            'no family sheet for $sens precedent "$slug"'));
      }
    }
  }
}
