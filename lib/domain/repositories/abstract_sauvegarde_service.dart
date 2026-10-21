import '../enums/mode_import.dart';

/// Contract for backing up and restoring the local database (implemented over
/// drift in the infrastructure layer).
///
/// Backups are **100% local**: the service produces/consumes a JSON [String];
/// writing it to disk and sharing it (native share sheet) is a Presentation
/// concern, so
/// no data ever leaves the device automatically.
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
