import '../../domain/entities/fiche_plante.dart';
import 'catalogue_yaml_parser.dart';
import 'fiche_asset_source.dart';
import 'fiche_plante_cache.dart';
import 'fiche_plante_mapper.dart';
import 'fiche_plante_validator.dart';

/// Orchestrates the catalogue loading pipeline: list → read → parse → validate →
/// map → cache.
///
/// Robustness (see `docs/07-base-de-connaissances-yaml.md` §6): a corrupt sheet
/// is reported through [_onErreur] and **skipped** — the app never crashes.
class CatalogueLoader {
  final FicheAssetSource _source;
  final void Function(String source, Object erreur)? _onErreur;
  final CatalogueYamlParser _parser = const CatalogueYamlParser();
  final FichePlanteValidator _validator = const FichePlanteValidator();
  final FichePlanteMapper _mapper = const FichePlanteMapper();

  CatalogueLoader(this._source, [this._onErreur]);

  /// Loads every available sheet and returns the populated cache. Invalid sheets
  /// are skipped (and reported), valid ones are kept.
  Future<FichePlanteCache> charger() async {
    final fiches = <FichePlante>[];
    for (final chemin in await _source.listerCheminsFiches()) {
      try {
        final contenu = await _source.lireFiche(chemin);
        final map = _parser.parser(contenu, source: chemin);
        _validator.valider(map, source: chemin);
        fiches.add(_mapper.versEntite(map));
      } catch (e) {
        // Reported, never silent, never fatal.
        _onErreur?.call(chemin, e);
      }
    }
    return FichePlanteCache(fiches);
  }
}
