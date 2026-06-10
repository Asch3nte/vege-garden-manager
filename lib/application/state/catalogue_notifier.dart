import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../providers/repository_providers.dart';
import 'catalogue_vue.dart';

/// Locale used for catalogue search and display (French-first app).
const String _locale = 'fr';

/// Drives the **Catalogue** screen: loads the plant catalogue once, then applies
/// the user's text query and category filter in memory.
///
/// The catalogue is small and fully in memory after the YAML load, so filtering
/// is a synchronous re-projection — no repository round-trip per keystroke. The
/// notifier keeps the full list privately and rebuilds the [CatalogueVue] on
/// every filter change.
class CatalogueNotifier extends AsyncNotifier<CatalogueVue> {
  List<FichePlante> _toutes = const [];
  String _requete = '';
  CategoriePlante? _categorie;

  @override
  Future<CatalogueVue> build() async {
    final repo = ref.watch(fichePlanteRepositoryProvider.future);
    _toutes = await (await repo).obtenirToutes();
    return _projeter();
  }

  /// Sets the free-text query and re-filters.
  void definirRequete(String requete) {
    _requete = requete;
    state = AsyncData(_projeter());
  }

  /// Sets the category filter (`null` = all categories) and re-filters.
  void definirCategorie(CategoriePlante? categorie) {
    _categorie = categorie;
    state = AsyncData(_projeter());
  }

  /// Applies the current filters to the loaded catalogue and orders the result
  /// by localized name.
  CatalogueVue _projeter() {
    final terme = _requete.trim().toLowerCase();

    final filtrees = _toutes.where((f) {
      if (_categorie != null && f.categorie != _categorie) return false;
      if (terme.isEmpty) return true;
      return f.nomLocalise(_locale).toLowerCase().contains(terme) ||
          f.id.toLowerCase().contains(terme);
    }).toList()
      ..sort((a, b) =>
          a.nomLocalise(_locale).compareTo(b.nomLocalise(_locale)));

    return CatalogueVue(
      requete: _requete,
      categorie: _categorie,
      fiches: filtrees,
      toutes: _toutes,
    );
  }
}

/// The Catalogue view-model provider.
final catalogueProvider =
    AsyncNotifierProvider<CatalogueNotifier, CatalogueVue>(
  CatalogueNotifier.new,
);
