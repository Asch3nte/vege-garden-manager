import 'package:yaml/yaml.dart';

import '../../domain/entities/bioagresseur.dart';
import '../../domain/exceptions/bioagresseur_invalide_exception.dart';
import 'bioagresseur_asset_source.dart';
import 'bioagresseur_cache.dart';
import 'bioagresseur_mapper.dart';
import 'bioagresseur_validator.dart';

/// Loads the bioaggressor reference in a single pass: read → parse → for each
/// entry validate → map → cache (ADR-0006, Lot 4).
///
/// Robustness mirrors the family reference: a corrupt entry is reported through
/// [_onErreur] and **skipped** — the app never crashes. A structurally broken
/// file yields an empty cache (reported), letting the integrity check surface
/// the consequences without aborting startup.
class BioagresseursLoader {
  final BioagresseurAssetSource _source;
  final void Function(String source, Object erreur)? _onErreur;
  final BioagresseurValidator _validator = const BioagresseurValidator();
  final BioagresseurMapper _mapper = const BioagresseurMapper();

  BioagresseursLoader(this._source, [this._onErreur]);

  /// Loads every reference entry and returns the populated cache.
  Future<BioagresseurCache> charger() async {
    final bioagresseurs = <Bioagresseur>[];
    Map entries;
    try {
      final contenu = await _source.lireReferentiel();
      final doc = loadYaml(contenu);
      if (doc is! Map) {
        throw BioagresseurInvalideException(
            cheminReferentielBioagresseurs, 'the root must be a mapping');
      }
      final brut = doc['bioagresseurs'];
      if (brut is! Map) {
        throw BioagresseurInvalideException(cheminReferentielBioagresseurs,
            'missing "bioagresseurs" mapping');
      }
      entries = brut;
    } on YamlException catch (e) {
      _onErreur?.call(
          cheminReferentielBioagresseurs,
          BioagresseurInvalideException(
              cheminReferentielBioagresseurs, 'YAML syntax error: ${e.message}'));
      return BioagresseurCache(const []);
    } catch (e) {
      _onErreur?.call(cheminReferentielBioagresseurs, e);
      return BioagresseurCache(const []);
    }

    for (final e in entries.entries) {
      final slug = e.key.toString();
      try {
        final entry = e.value;
        if (entry is! Map) {
          throw BioagresseurInvalideException(slug, 'entry must be a mapping');
        }
        _validator.valider(slug, entry, source: slug);
        bioagresseurs.add(_mapper.versEntite(slug, entry));
      } catch (err) {
        // Reported, never silent, never fatal.
        _onErreur?.call(slug, err);
      }
    }
    return BioagresseurCache(bioagresseurs);
  }
}
