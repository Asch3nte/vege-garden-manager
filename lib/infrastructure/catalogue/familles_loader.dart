import 'package:yaml/yaml.dart';

import '../../domain/exceptions/famille_botanique_invalide_exception.dart';
import 'famille_asset_source.dart';
import 'famille_botanique_cache.dart';
import 'famille_botanique_mapper.dart';
import 'famille_botanique_validator.dart';

/// Loads the botanical-family reference in a single pass: list → read → parse →
/// validate → map → cache (ADR-0006). Families carry no inheritance, so unlike
/// the plant catalogue no second pass is needed.
///
/// Robustness mirrors the plant catalogue: a corrupt family sheet is reported
/// through [_onErreur] and **skipped** — the app never crashes.
class FamillesLoader {
  final FamilleAssetSource _source;
  final void Function(String source, Object erreur)? _onErreur;
  final FamilleBotaniqueValidator _validator = const FamilleBotaniqueValidator();
  final FamilleBotaniqueMapper _mapper = const FamilleBotaniqueMapper();

  FamillesLoader(this._source, [this._onErreur]);

  /// Loads every available family sheet and returns the populated cache.
  /// Invalid or corrupt sheets are skipped (and reported), valid ones are kept.
  Future<FamilleBotaniqueCache> charger() async {
    final familles = <dynamic>[];
    for (final chemin in await _source.listerCheminsFamilles()) {
      try {
        final contenu = await _source.lireFamille(chemin);
        final doc = loadYaml(contenu);
        if (doc is! Map) {
          throw FamilleBotaniqueInvalideException(
              chemin, 'the root must be a mapping');
        }
        _validator.valider(doc, source: chemin);
        familles.add(_mapper.versEntite(doc));
      } on YamlException catch (e) {
        _onErreur?.call(chemin,
            FamilleBotaniqueInvalideException(chemin, 'YAML syntax error: ${e.message}'));
      } catch (e) {
        // Reported, never silent, never fatal.
        _onErreur?.call(chemin, e);
      }
    }
    return FamilleBotaniqueCache(familles.cast());
  }
}
