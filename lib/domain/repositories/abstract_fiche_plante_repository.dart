import '../entities/fiche_plante.dart';
import '../enums/categorie_plante.dart';
import '../enums/usage_plante.dart';

/// Contract for reading the plant catalogue (loaded from YAML, never written by
/// the user through this contract).
abstract class AbstractFichePlanteRepository {
  Future<List<FichePlante>> obtenirToutes();
  Future<FichePlante?> obtenirParId(String id);
  Future<List<FichePlante>> rechercher(String terme, String locale);
  Future<List<FichePlante>> filtrerParCategorie(CategoriePlante categorie);
  Future<List<FichePlante>> filtrerParUsage(UsagePlante usage);
}
