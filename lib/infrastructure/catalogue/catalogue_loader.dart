import '../../domain/entities/fiche_plante.dart';
import '../../domain/exceptions/fiche_plante_invalide_exception.dart';
import 'catalogue_yaml_parser.dart';
import 'fiche_asset_source.dart';
import 'fiche_plante_cache.dart';
import 'fiche_plante_mapper.dart';
import 'fiche_plante_validator.dart';
import 'fusionneur_fiches.dart';

/// A sheet read and parsed in pass 1, awaiting inheritance resolution.
class _FicheBrute {
  final String chemin;
  final Map<dynamic, dynamic> map;
  const _FicheBrute(this.chemin, this.map);
}

/// Orchestrates the catalogue loading pipeline in **two passes**:
/// list → read → parse (pass 1), then resolve species/variety inheritance →
/// validate → map → cache (pass 2). The second pass needs every mother sheet
/// already parsed, hence the split (ADR-0005).
///
/// Robustness (see `docs/07-base-de-connaissances-yaml.md` §6): a corrupt or
/// orphan sheet is reported through [_onErreur] and **skipped** — the app never
/// crashes.
class CatalogueLoader {
  final FicheAssetSource _source;
  final void Function(String source, Object erreur)? _onErreur;
  final CatalogueYamlParser _parser = const CatalogueYamlParser();
  // Catalogue is migrated to canonical ADR-0005 ids → enforce the format.
  final FichePlanteValidator _validator =
      const FichePlanteValidator(validerFormatId: true);
  final FichePlanteMapper _mapper = const FichePlanteMapper();
  final FusionneurFiches _fusionneur = const FusionneurFiches();

  CatalogueLoader(this._source, [this._onErreur]);

  /// Loads every available sheet and returns the populated cache. Invalid,
  /// corrupt or orphan sheets are skipped (and reported), valid ones are kept.
  Future<FichePlanteCache> charger() async {
    // Pass 1 — read & parse every sheet, indexing parseable ones by id so
    // varieties can resolve their mother.
    final aTraiter = <_FicheBrute>[];
    final fichesParId = <String, Map<dynamic, dynamic>>{};
    for (final chemin in await _source.listerCheminsFiches()) {
      try {
        final contenu = await _source.lireFiche(chemin);
        final map = _parser.parser(contenu, source: chemin);
        aTraiter.add(_FicheBrute(chemin, map));
        final id = map['id'];
        if (id is String) fichesParId[id] = map;
      } catch (e) {
        // Reported, never silent, never fatal.
        _onErreur?.call(chemin, e);
      }
    }

    // Pass 2 — resolve inheritance (variety ⟵ mother), validate, map.
    final fiches = <FichePlante>[];
    for (final brute in aTraiter) {
      try {
        var map = brute.map;
        final parentId = map['parent_id'];
        if (parentId != null) {
          final mere = fichesParId[parentId];
          if (mere == null) {
            throw FichePlanteInvalideException(
              brute.chemin,
              'parent_id "$parentId" introuvable',
            );
          }
          map = _fusionneur.fusionner(mere, map);
        }
        _validator.valider(map, source: brute.chemin);
        fiches.add(_mapper.versEntite(map));
      } catch (e) {
        _onErreur?.call(brute.chemin, e);
      }
    }
    return FichePlanteCache(fiches);
  }
}
