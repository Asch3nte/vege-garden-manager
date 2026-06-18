import '../entities/bioagresseur.dart';
import '../enums/type_bioagresseur.dart';

/// Read-only access to the embedded bioaggressor reference (ADR-0006, Lot 4).
///
/// The reference is shipped with the app and never mutated by the user, so the
/// interface only exposes lookups. Backed by the in-memory cache built at load.
abstract class AbstractBioagresseurRepository {
  /// Every known bioaggressor (immutable list).
  Future<List<Bioagresseur>> obtenirTous();

  /// The bioaggressor with [id] (normalized slug), or `null` if unknown.
  Future<Bioagresseur?> obtenirParId(String id);

  /// Bioaggressors of the given [type] (diseases or pests).
  Future<List<Bioagresseur>> filtrerParType(TypeBioagresseur type);
}
