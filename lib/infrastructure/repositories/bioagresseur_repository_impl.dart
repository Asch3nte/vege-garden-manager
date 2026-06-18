import '../../domain/entities/bioagresseur.dart';
import '../../domain/enums/type_bioagresseur.dart';
import '../../domain/repositories/abstract_bioagresseur_repository.dart';
import '../catalogue/bioagresseur_cache.dart';

/// [AbstractBioagresseurRepository] backed by the in-memory [BioagresseurCache]
/// built from the embedded reference at load time (ADR-0006, Lot 4).
class BioagresseurRepositoryImpl implements AbstractBioagresseurRepository {
  final BioagresseurCache _cache;

  const BioagresseurRepositoryImpl(this._cache);

  @override
  Future<List<Bioagresseur>> obtenirTous() async => _cache.tous();

  @override
  Future<Bioagresseur?> obtenirParId(String id) async => _cache.parId(id);

  @override
  Future<List<Bioagresseur>> filtrerParType(TypeBioagresseur type) async =>
      _cache.parType(type);
}
