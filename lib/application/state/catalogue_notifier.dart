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

  /// Applies the current filters and groups the result by species (mother sheet
  /// + its varieties), ordered by localized name.
  ///
  /// A species is shown when its category matches and either the query is empty,
  /// the species itself matches, or one of its varieties matches. When only
  /// varieties match, just those are expanded under the species; otherwise all
  /// of them are.
  CatalogueVue _projeter() {
    final terme = _requete.trim().toLowerCase();
    int parNom(FichePlante a, FichePlante b) =>
        a.nomLocalise(_locale).compareTo(b.nomLocalise(_locale));
    bool correspond(FichePlante f) =>
        f.nomLocalise(_locale).toLowerCase().contains(terme) ||
        f.id.toLowerCase().contains(terme);

    final meres = _toutes.where((f) => f.estMere).toList()..sort(parNom);
    final varietesParParent = <String, List<FichePlante>>{};
    for (final f in _toutes.where((f) => f.estVariete)) {
      (varietesParParent[f.parentId!] ??= []).add(f);
    }

    final groupes = <GroupeFiche>[];
    for (final mere in meres) {
      if (_categorie != null && mere.categorie != _categorie) continue;
      final varietes = [...?varietesParParent[mere.id]]..sort(parNom);
      if (terme.isEmpty || correspond(mere)) {
        groupes.add(GroupeFiche(mere: mere, varietes: varietes));
      } else {
        final filtrees = varietes.where(correspond).toList();
        if (filtrees.isNotEmpty) {
          groupes.add(GroupeFiche(mere: mere, varietes: filtrees));
        }
      }
    }

    return CatalogueVue(
      requete: _requete,
      categorie: _categorie,
      groupes: groupes,
      toutesMeres: meres,
    );
  }
}

/// The Catalogue view-model provider.
final catalogueProvider =
    AsyncNotifierProvider<CatalogueNotifier, CatalogueVue>(
  CatalogueNotifier.new,
);
