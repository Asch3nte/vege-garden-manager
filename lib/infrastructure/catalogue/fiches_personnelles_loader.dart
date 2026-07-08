import '../../domain/entities/fiche_plante.dart';
import '../../domain/repositories/abstract_fiche_plante_personnelle_repository.dart';
import 'catalogue_yaml_parser.dart';
import 'fiche_plante_mapper.dart';
import 'fiche_plante_validator.dart';

/// Loads user-authored sheets from the database and turns them into catalogue
/// [FichePlante] entities, ready to be merged with the embedded catalogue.
///
/// Runs the same pipeline as [CatalogueLoader] (parse → validate → map) on each
/// stored `yaml_contenu`, but **without** the canonical id-format check
/// (`validerFormatId: false`): personal ids live in their own namespace. Sheets
/// carry no inheritance (no `parent_id`), so no mother resolution is needed.
///
/// Robustness (see `docs/07-base-de-connaissances-yaml.md` §6): a corrupt sheet
/// is reported through [_onErreur] and **skipped** — the catalogue still loads.
class FichesPersonnellesLoader {
  final AbstractFichePlantePersonnelleRepository _repo;
  final void Function(String source, Object erreur)? _onErreur;
  final CatalogueYamlParser _parser = const CatalogueYamlParser();
  final FichePlanteValidator _validator =
      const FichePlanteValidator(validerFormatId: false);
  final FichePlanteMapper _mapper = const FichePlanteMapper();

  FichesPersonnellesLoader(this._repo, [this._onErreur]);

  /// Parses, validates and maps every non-deleted personal sheet, skipping
  /// (and reporting) any corrupt one.
  Future<List<FichePlante>> charger() async {
    final fiches = <FichePlante>[];
    for (final contenu in await _repo.obtenirYamlBruts()) {
      const source = 'fiche personnelle';
      try {
        final map = _parser.parser(contenu, source: source);
        _validator.valider(map, source: source);
        fiches.add(_mapper.versEntite(map));
      } catch (e) {
        // Reported, never silent, never fatal.
        _onErreur?.call(source, e);
      }
    }
    return fiches;
  }
}
