import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/type_bioagresseur.dart';
import 'bioagresseur_cache.dart';

/// A single referential-integrity problem between a plant sheet's targeted
/// defence (`repulsif_contre` / `piege_a`) and the bioaggressor reference
/// (ADR-0010, Lot 2).
class ProblemeIntegriteRepulsif {
  /// Offending species id.
  final String espece;

  /// Human-readable reason.
  final String raison;

  const ProblemeIntegriteRepulsif(this.espece, this.raison);

  @override
  String toString() => '$espece: $raison';
}

/// Cross-checks that the plant catalogue's targeted-defence slugs resolve in the
/// bioaggressor reference (ADR-0010, Lot 2):
///
/// 1. **Coverage** — every slug listed in `repulsif_contre` / `piege_a` must
///    resolve to a reference entry.
/// 2. **Coherence** — a trapped slug (`piege_a`) must be a `ravageur`: you trap
///    an animal pest, not a disease. A repelled slug may be either type.
///
/// Pure and non-fatal: it *reports* problems (it never throws), so callers can
/// log them without aborting the load. The shipped catalogue is guarded green by
/// `catalogue_reel_test.dart`.
class VerificateurIntegriteRepulsifs {
  const VerificateurIntegriteRepulsifs();

  /// Returns every problem found for [especes] against [reference] (empty when
  /// coherent).
  List<ProblemeIntegriteRepulsif> verifier(
    Iterable<FichePlante> especes,
    BioagresseurCache reference,
  ) {
    final problemes = <ProblemeIntegriteRepulsif>[];

    for (final espece in especes) {
      for (final slug in espece.repulsifContre) {
        if (reference.parId(slug) == null) {
          problemes.add(ProblemeIntegriteRepulsif(espece.id,
              'unknown repulsif_contre slug "$slug" in the reference'));
        }
      }
      for (final slug in espece.piegeA) {
        final b = reference.parId(slug);
        if (b == null) {
          problemes.add(ProblemeIntegriteRepulsif(
              espece.id, 'unknown piege_a slug "$slug" in the reference'));
        } else if (b.type != TypeBioagresseur.ravageur) {
          problemes.add(ProblemeIntegriteRepulsif(espece.id,
              'piege_a slug "$slug" is a ${b.type.name}, not a ravageur'));
        }
      }
    }
    return problemes;
  }
}
