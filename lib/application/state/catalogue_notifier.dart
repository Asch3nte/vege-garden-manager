import 'package:riverpod/riverpod.dart';

import '../../domain/entities/famille_botanique.dart';
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
  Map<String, FamilleBotanique> _famillesParId = const {};
  String _requete = '';
  CategoriePlante? _categorie;
  String? _famille;

  @override
  Future<CatalogueVue> build() async {
    final repo = await ref.watch(fichePlanteRepositoryProvider.future);
    _toutes = await repo.obtenirToutes();
    final repoFamilles =
        await ref.watch(familleBotaniqueRepositoryProvider.future);
    _famillesParId = {
      for (final f in await repoFamilles.obtenirToutes()) f.id: f
    };
    return _projeter();
  }

  /// Sets the free-text query and re-filters.
  void definirRequete(String requete) {
    _requete = requete;
    state = AsyncData(_projeter());
  }

  /// Sets the category filter (`null` = all categories) and re-filters. Changing
  /// category clears the family sub-filter, which is scoped to a category.
  void definirCategorie(CategoriePlante? categorie) {
    _categorie = categorie;
    _famille = null;
    state = AsyncData(_projeter());
  }

  /// Sets the family sub-filter (`null` = all families of the category) and
  /// re-filters (ADR-0006).
  void definirFamille(String? familleId) {
    _famille = familleId;
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
    String cleFamille(FichePlante f) =>
        FamilleBotanique.normaliserCle(f.familleBotanique);

    final meres = _toutes.where((f) => f.estMere).toList()..sort(parNom);
    final varietesParParent = <String, List<FichePlante>>{};
    for (final f in _toutes.where((f) => f.estVariete)) {
      (varietesParParent[f.parentId!] ??= []).add(f);
    }

    final groupes = <GroupeFiche>[];
    for (final mere in meres) {
      if (_categorie != null && mere.categorie != _categorie) continue;
      if (_famille != null && cleFamille(mere) != _famille) continue;
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
      familleSelectionnee: _famille,
      familles: _famillesDeCategorie(meres),
      groupes: groupes,
      toutesMeres: meres,
    );
  }

  /// Family chips for the selected category: the botanical families present
  /// among that category's species, resolved to their entity (for localized
  /// names) and ordered by name. Empty when no category is selected (ADR-0006).
  List<FamilleBotanique> _famillesDeCategorie(List<FichePlante> meres) {
    if (_categorie == null) return const [];
    final cles = <String>{
      for (final m in meres)
        if (m.categorie == _categorie)
          FamilleBotanique.normaliserCle(m.familleBotanique),
    };
    final familles = [
      for (final cle in cles)
        if (_famillesParId[cle] != null) _famillesParId[cle]!,
    ]..sort((a, b) => a.nomLocalise(_locale).compareTo(b.nomLocalise(_locale)));
    return familles;
  }
}

/// The Catalogue view-model provider.
final catalogueProvider =
    AsyncNotifierProvider<CatalogueNotifier, CatalogueVue>(
  CatalogueNotifier.new,
);
