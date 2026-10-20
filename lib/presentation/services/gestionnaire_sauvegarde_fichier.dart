import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/exceptions/sauvegarde_invalide_exception.dart';

/// Moves a backup **document** in and out of the app via the platform.
///
/// This is the Presentation-side counterpart of `AbstractSauvegardeService`
/// (which only turns the database into / from a JSON string): here we write that
/// string to a file and open the native **share sheet**, or let the user **pick**
/// a backup file and read it back. Nothing is sent over the network — sharing is
/// driven entirely by the user. The plugin calls are isolated behind this
/// interface so the panel logic stays unit-testable with a fake.
abstract class AbstractGestionnaireSauvegardeFichier {
  /// Writes [contenu] to a file named [nomFichier] and opens the
  /// native share sheet on it.
  Future<void> partager(String contenu, String nomFichier);

  /// Opens a file picker and returns the chosen file's text content, or `null`
  /// if the user cancelled. Throws [SauvegardeInvalideException] when the file
  /// is unreadable or not UTF-8 text.
  Future<String?> choisirEtLire();
}

/// share_plus + file_picker implementation.
///
/// Exports are written to an app-private cache folder that keeps only the
/// latest one: the share target may read the file after the sheet closes, so
/// it cannot be deleted right away.
class GestionnaireSauvegardeFichier
    implements AbstractGestionnaireSauvegardeFichier {
  static const _sousDossier = 'exports';

  final Future<Directory> Function() _dossierCache;
  final Future<void> Function(String chemin, String sujet) _partagerFichier;
  final Future<List<int>?> Function() _lireFichierChoisi;

  GestionnaireSauvegardeFichier({
    Future<Directory> Function()? dossierCache,
    Future<void> Function(String chemin, String sujet)? partagerFichier,
    Future<List<int>?> Function()? lireFichierChoisi,
  })  : _dossierCache = dossierCache ?? getApplicationCacheDirectory,
        _partagerFichier = partagerFichier ?? _partagerViaPlateforme,
        _lireFichierChoisi = lireFichierChoisi ?? _lireViaSelecteur;

  static Future<void> _partagerViaPlateforme(String chemin, String sujet) =>
      SharePlus.instance
          .share(ShareParams(files: [XFile(chemin)], subject: sujet));

  static Future<List<int>?> _lireViaSelecteur() async {
    final fichier = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    return fichier?.readAsBytes();
  }

  @override
  Future<void> partager(String contenu, String nomFichier) async {
    final dossier =
        Directory(p.join((await _dossierCache()).path, _sousDossier));
    await dossier.create(recursive: true);
    await for (final ancien in dossier.list()) {
      try {
        await ancien.delete(recursive: true);
      } on FileSystemException catch (e) {
        // Still held by a share target; removed by a later export.
        debugPrint('Export cleanup skipped: $e');
      }
    }
    final fichier = File(p.join(dossier.path, nomFichier));
    await fichier.writeAsString(contenu);
    await _partagerFichier(fichier.path, nomFichier);
  }

  @override
  Future<String?> choisirEtLire() async {
    try {
      final octets = await _lireFichierChoisi();
      return octets == null ? null : utf8.decode(octets);
    } on FileSystemException catch (e) {
      throw SauvegardeInvalideException('Backup file is unreadable.', cause: e);
    } on FormatException catch (e) {
      throw SauvegardeInvalideException('Backup file is not UTF-8 text.',
          cause: e);
    }
  }
}

final gestionnaireSauvegardeFichierProvider =
    Provider<AbstractGestionnaireSauvegardeFichier>(
  (ref) => GestionnaireSauvegardeFichier(),
);
