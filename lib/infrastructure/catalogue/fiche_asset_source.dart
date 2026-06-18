import 'package:flutter/services.dart';

/// Abstraction over the source of plant-sheet assets, so the catalogue loader
/// can be tested without the Flutter asset bundle.
abstract class FicheAssetSource {
  /// Paths of every plant-sheet YAML file available.
  Future<List<String>> listerCheminsFiches();

  /// Raw YAML content of the sheet at [chemin].
  Future<String> lireFiche(String chemin);
}

/// [FicheAssetSource] backed by the Flutter asset bundle (`rootBundle` by
/// default). Lists `assets/fiches_plantes/<categorie>/*.yaml`, excluding the
/// `_schema/`, `_familles/` and `_referentiels/` folders (the latter two hold
/// family sheets and the bioaggressor reference, distinct entities loaded by
/// their own pipelines — ADR-0006).
class BundleFicheAssetSource implements FicheAssetSource {
  final AssetBundle _bundle;

  BundleFicheAssetSource([AssetBundle? bundle]) : _bundle = bundle ?? rootBundle;

  @override
  Future<List<String>> listerCheminsFiches() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    return manifest
        .listAssets()
        .where((p) =>
            p.startsWith('assets/fiches_plantes/') &&
            p.endsWith('.yaml') &&
            !p.contains('/_schema/') &&
            !p.contains('/_familles/') &&
            !p.contains('/_referentiels/'))
        .toList();
  }

  @override
  Future<String> lireFiche(String chemin) => _bundle.loadString(chemin);
}
