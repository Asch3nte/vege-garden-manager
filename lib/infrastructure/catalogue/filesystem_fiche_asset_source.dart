import 'dart:io';

import 'fiche_asset_source.dart';

/// [FicheAssetSource] backed by the local filesystem instead of the Flutter
/// asset bundle.
///
/// Lets the catalogue pipeline run outside a Flutter context — in pure-Dart
/// scripts (`bin/`) and in tooling — where `rootBundle` is unavailable. Reads
/// the same `assets/fiches_plantes/<categorie>/*.yaml` tree that
/// [BundleFicheAssetSource] exposes at runtime, excluding the `_schema/` and
/// `_familles/` folders.
class FilesystemFicheAssetSource implements FicheAssetSource {
  /// Root of the plant-sheet tree (defaults to the repo's `assets/` location).
  final Directory _racine;

  FilesystemFicheAssetSource([String racine = 'assets/fiches_plantes'])
      : _racine = Directory(racine);

  @override
  Future<List<String>> listerCheminsFiches() async {
    if (!_racine.existsSync()) return const [];
    return _racine
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path)
        .where((p) =>
            p.endsWith('.yaml') &&
            !p.contains('/_schema/') &&
            !p.contains('/_familles/'))
        .toList();
  }

  @override
  Future<String> lireFiche(String chemin) => File(chemin).readAsString();
}
