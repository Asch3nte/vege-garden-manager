import 'dart:io';

import 'fiche_asset_source.dart';

/// [FicheAssetSource] backed by the local filesystem instead of the Flutter
/// asset bundle.
///
/// Lets the catalogue pipeline run outside a Flutter context — in pure-Dart
/// scripts (`bin/`) and in tooling — where `rootBundle` is unavailable. Reads
/// the same `assets/fiches_plantes/<categorie>/*.yaml` tree that
/// [BundleFicheAssetSource] exposes at runtime, excluding the `_schema/`,
/// `_familles/` and `_referentiels/` folders.
class FilesystemFicheAssetSource implements FicheAssetSource {
  /// Root of the plant-sheet tree (defaults to the repo's `assets/` location).
  final Directory _racine;

  FilesystemFicheAssetSource([String racine = 'assets/fiches_plantes'])
      : _racine = Directory(racine);

  @override
  Future<List<String>> listerCheminsFiches() async {
    if (!_racine.existsSync()) return const [];
    return List.unmodifiable(_racine
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path)
        .where(estFiche));
  }

  /// Whether [chemin] is a plant sheet, whatever the platform's separator.
  static bool estFiche(String chemin) {
    final p = chemin.replaceAll(r'\', '/');
    return p.endsWith('.yaml') &&
        !p.contains('/_schema/') &&
        !p.contains('/_familles/') &&
        !p.contains('/_referentiels/');
  }

  @override
  Future<String> lireFiche(String chemin) => File(chemin).readAsString();
}
