import '../../domain/entities/famille_botanique.dart';
import '../../domain/enums/type_bioagresseur.dart';
import 'bioagresseur_cache.dart';

/// A single referential-integrity problem between a family sheet and the
/// bioaggressor reference (ADR-0006, Lot 4).
class ProblemeIntegriteBioagresseur {
  /// Offending family id.
  final String famille;

  /// Human-readable reason.
  final String raison;

  const ProblemeIntegriteBioagresseur(this.famille, this.raison);

  @override
  String toString() => '$famille: $raison';
}

/// Cross-checks that the family sheets and the bioaggressor reference are
/// coherent (ADR-0006, Lot 4):
///
/// 1. **Coverage** — every slug listed in a family's `maladies_communes` /
///    `ravageurs_communs` must resolve to a reference entry.
/// 2. **Coherence** — a slug listed under diseases must have `type: maladie`,
///    and a slug listed under pests must have `type: ravageur`.
///
/// Pure and non-fatal: it *reports* problems (it never throws), so callers can
/// log them without aborting the load. The shipped reference is guarded green
/// by `bioagresseurs_reel_test.dart`.
class VerificateurIntegriteBioagresseurs {
  const VerificateurIntegriteBioagresseurs();

  /// Returns every problem found for [familles] against [reference] (empty when
  /// coherent).
  List<ProblemeIntegriteBioagresseur> verifier(
    Iterable<FamilleBotanique> familles,
    BioagresseurCache reference,
  ) {
    final problemes = <ProblemeIntegriteBioagresseur>[];

    void controler(
        FamilleBotanique f, Set<String> slugs, TypeBioagresseur attendu) {
      for (final slug in slugs) {
        final b = reference.parId(slug);
        if (b == null) {
          problemes.add(ProblemeIntegriteBioagresseur(
              f.id, 'unknown ${attendu.name} slug "$slug" in the reference'));
        } else if (b.type != attendu) {
          problemes.add(ProblemeIntegriteBioagresseur(f.id,
              'slug "$slug" is a ${b.type.name}, not a ${attendu.name}'));
        }
      }
    }

    for (final f in familles) {
      controler(f, f.maladiesCommunes, TypeBioagresseur.maladie);
      controler(f, f.ravageursCommuns, TypeBioagresseur.ravageur);
    }
    return problemes;
  }
}
