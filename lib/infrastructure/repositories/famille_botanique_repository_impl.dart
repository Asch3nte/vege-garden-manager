import '../../domain/entities/famille_botanique.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/repositories/abstract_famille_botanique_repository.dart';
import '../catalogue/famille_botanique_cache.dart';

/// [AbstractFamilleBotaniqueRepository] backed by the in-memory
/// [FamilleBotaniqueCache]. The reference is read-only at runtime (loaded from
/// YAML), so all queries are served from the cache.
class FamilleBotaniqueRepositoryImpl
    implements AbstractFamilleBotaniqueRepository {
  final FamilleBotaniqueCache _cache;

  FamilleBotaniqueRepositoryImpl(this._cache);

  @override
  Future<List<FamilleBotanique>> obtenirToutes() async => _cache.toutes();

  @override
  Future<FamilleBotanique?> obtenirParId(String id) async => _cache.parId(id);

  @override
  Future<List<FamilleBotanique>> filtrerParCategorie(
          CategoriePlante categorie) async =>
      _cache.parCategorie(categorie);
}
