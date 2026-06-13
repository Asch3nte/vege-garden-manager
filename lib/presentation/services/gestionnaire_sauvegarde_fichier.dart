import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Moves a backup **document** in and out of the app via the platform.
///
/// This is the Presentation-side counterpart of `AbstractSauvegardeService`
/// (which only turns the database into / from a JSON string): here we write that
/// string to a file and open the native **share sheet**, or let the user **pick**
/// a backup file and read it back. Nothing is sent over the network — sharing is
/// driven entirely by the user. The plugin calls are isolated behind this
/// interface so the panel logic stays unit-testable with a fake.
abstract class AbstractGestionnaireSauvegardeFichier {
  /// Writes [contenu] to a temporary file named [nomFichier] and opens the
  /// native share sheet on it.
  Future<void> partager(String contenu, String nomFichier);

  /// Opens a file picker and returns the chosen file's text content, or `null`
  /// if the user cancelled.
  Future<String?> choisirEtLire();
}

/// share_plus + file_picker implementation.
class GestionnaireSauvegardeFichier
    implements AbstractGestionnaireSauvegardeFichier {
  const GestionnaireSauvegardeFichier();

  @override
  Future<void> partager(String contenu, String nomFichier) async {
    final dossier = await getTemporaryDirectory();
    final fichier = File(p.join(dossier.path, nomFichier));
    await fichier.writeAsString(contenu);
    await Share.shareXFiles([XFile(fichier.path)], subject: nomFichier);
  }

  @override
  Future<String?> choisirEtLire() async {
    final resultat = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final fichier = resultat?.files.singleOrNull;
    if (fichier == null) return null;
    if (fichier.bytes != null) return utf8.decode(fichier.bytes!);
    if (fichier.path != null) return File(fichier.path!).readAsString();
    return null;
  }
}

final gestionnaireSauvegardeFichierProvider =
    Provider<AbstractGestionnaireSauvegardeFichier>(
  (ref) => const GestionnaireSauvegardeFichier(),
);
