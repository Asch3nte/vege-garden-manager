import 'dart:io';

import 'package:flutter/services.dart';

/// Abstraction over the source of family-sheet assets, so the families loader
/// can be tested without the Flutter asset bundle (mirrors `FicheAssetSource`).
abstract class FamilleAssetSource {
  /// Paths of every family-sheet YAML file available (registry index excluded).
  Future<List<String>> listerCheminsFamilles();

  /// Raw YAML content of the family sheet at [chemin].
  Future<String> lireFamille(String chemin);
}

/// True for a family-sheet YAML path: under `_familles/`, a `.yaml` file, and
/// not the human-readable registry index.
bool _estFicheFamille(String chemin) =>
    chemin.contains('assets/fiches_plantes/_familles/') &&
    chemin.endsWith('.yaml') &&
    !chemin.endsWith('familles_registry.yaml');

/// [FamilleAssetSource] backed by the Flutter asset bundle (`rootBundle` by
/// default). Lists `assets/fiches_plantes/_familles/*.yaml`, excluding the
/// `familles_registry.yaml` index.
class BundleFamilleAssetSource implements FamilleAssetSource {
  final AssetBundle _bundle;

  BundleFamilleAssetSource([AssetBundle? bundle])
      : _bundle = bundle ?? rootBundle;

  @override
  Future<List<String>> listerCheminsFamilles() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    return manifest.listAssets().where(_estFicheFamille).toList();
  }

  @override
  Future<String> lireFamille(String chemin) => _bundle.loadString(chemin);
}

/// [FamilleAssetSource] backed by the local filesystem, for pure-Dart scripts
/// and tooling where `rootBundle` is unavailable (mirrors
/// `FilesystemFicheAssetSource`).
class FilesystemFamilleAssetSource implements FamilleAssetSource {
  /// Root of the family-sheet folder.
  final Directory _racine;

  FilesystemFamilleAssetSource(
      [String racine = 'assets/fiches_plantes/_familles'])
      : _racine = Directory(racine);

  @override
  Future<List<String>> listerCheminsFamilles() async {
    if (!_racine.existsSync()) return const [];
    return _racine
        .listSync(recursive: false)
        .whereType<File>()
        .map((f) => f.path)
        .where((p) =>
            p.endsWith('.yaml') && !p.endsWith('familles_registry.yaml'))
        .toList();
  }

  @override
  Future<String> lireFamille(String chemin) => File(chemin).readAsString();
}
