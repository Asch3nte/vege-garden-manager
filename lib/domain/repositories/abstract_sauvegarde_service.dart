import '../enums/mode_import.dart';

/// Contract for backing up and restoring the local database (implemented over
/// drift in the infrastructure layer).
///
/// Backups are **100% local**: the service produces/consumes a JSON [String];
/// writing it to disk and sharing it (native share sheet — see
/// `docs/12-internationalisation-et-donnees.md`) is a Presentation concern, so
/// no data ever leaves the device automatically.
///
/// See `docs/05-modele-de-domaine.md` §7 and `docs/11-parametres-et-opt-outs.md` §5.
abstract class AbstractSauvegardeService {
  /// Serialises the whole database to a single JSON document.
  Future<String> exporterJson();

  /// Restores data from a [json] document produced by [exporterJson],
  /// according to [mode] (replace everything, or merge by id).
  ///
  /// Throws `SauvegardeInvalideException` if [json] is malformed or its schema
  /// version is unsupported.
  Future<void> importerJson(String json, ModeImport mode);
}
