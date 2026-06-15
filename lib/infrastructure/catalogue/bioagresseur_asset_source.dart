import 'dart:io';

import 'package:flutter/services.dart';

/// Abstraction over the source of the bioaggressor reference, so the loader can
/// be tested without the Flutter asset bundle (mirrors `FamilleAssetSource`).
///
/// Unlike families (one file per sheet), the reference is a **single** YAML
/// document, so the source only exposes a single read.
abstract class BioagresseurAssetSource {
  /// Raw YAML content of the bioaggressor reference.
  Future<String> lireReferentiel();
}

/// Canonical asset path of the embedded bioaggressor reference.
const String cheminReferentielBioagresseurs =
    'assets/fiches_plantes/_referentiels/bioagresseurs.yaml';

/// [BioagresseurAssetSource] backed by the Flutter asset bundle (`rootBundle`
/// by default).
class BundleBioagresseurAssetSource implements BioagresseurAssetSource {
  final AssetBundle _bundle;

  BundleBioagresseurAssetSource([AssetBundle? bundle])
      : _bundle = bundle ?? rootBundle;

  @override
  Future<String> lireReferentiel() =>
      _bundle.loadString(cheminReferentielBioagresseurs);
}

/// [BioagresseurAssetSource] backed by the local filesystem, for pure-Dart
/// scripts and tooling where `rootBundle` is unavailable (mirrors
/// `FilesystemFamilleAssetSource`).
class FilesystemBioagresseurAssetSource implements BioagresseurAssetSource {
  final File _fichier;

  FilesystemBioagresseurAssetSource(
      [String chemin = cheminReferentielBioagresseurs])
      : _fichier = File(chemin);

  @override
  Future<String> lireReferentiel() => _fichier.readAsString();
}
