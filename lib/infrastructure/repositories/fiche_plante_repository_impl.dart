import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/usage_plante.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../catalogue/fiche_plante_cache.dart';

/// [AbstractFichePlanteRepository] backed by the in-memory [FichePlanteCache].
///
/// The catalogue is read-only at runtime (loaded from YAML), so all queries are
/// served from the cache.
class FichePlanteRepositoryImpl implements AbstractFichePlanteRepository {
  final FichePlanteCache _cache;

  FichePlanteRepositoryImpl(this._cache);

  @override
  Future<List<FichePlante>> obtenirToutes() async => _cache.toutes();

  @override
  Future<FichePlante?> obtenirParId(String id) async => _cache.parId(id);

  @override
  Future<List<FichePlante>> rechercher(String terme, String locale) async =>
      _cache.rechercher(terme, locale);

  @override
  Future<List<FichePlante>> filtrerParCategorie(CategoriePlante categorie) async =>
      _cache.parCategorie(categorie);

  @override
  Future<List<FichePlante>> filtrerParUsage(UsagePlante usage) async =>
      _cache.parUsage(usage);
}
