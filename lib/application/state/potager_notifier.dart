import 'package:riverpod/riverpod.dart';

import '../../domain/entities/parcelle.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/statut_plantation.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../providers/horloge_provider.dart';
import '../providers/repository_providers.dart';
import 'potager_vue.dart';

/// Locale used to resolve crop display names (French-first app).
const String _locale = 'fr';

/// Assembles the **Potager** view-model: the active garden's zones, each with
/// its active crops (resolved from the catalogue) and a "task due today" flag.
///
/// Composition only — it reads existing repositories and the catalogue, adding
/// no persistence. Crop names come from the plant catalogue because a
/// `Plantation` stores a plant id, not a name. A missing fiche degrades to a
/// skipped crop rather than an error (the zone still lists its other crops).
class PotagerNotifier extends AsyncNotifier<PotagerVue> {
  @override
  Future<PotagerVue> build() async {
    final potagers = ref.watch(potagerRepositoryProvider);
    final parcelles = ref.watch(parcelleRepositoryProvider);
    final plantations = ref.watch(plantationRepositoryProvider);
    // The catalogue loads from YAML assets asynchronously.
    final fiches = await ref.watch(fichePlanteRepositoryProvider.future);
    final taches = ref.watch(tacheRepositoryProvider);
    final maintenant = ref.watch(horlogeProvider);

    return _assembler(potagers, parcelles, plantations, fiches, taches, maintenant);
  }

  Future<PotagerVue> _assembler(
    AbstractPotagerRepository potagers,
    AbstractParcelleRepository parcelles,
    AbstractPlantationRepository plantations,
    AbstractFichePlanteRepository fiches,
    AbstractTacheRepository taches,
    DateTime Function() maintenant,
  ) async {
    final potager = await potagers.obtenirPotagerActif();
    if (potager == null) {
      return PotagerVue(potagerId: null, nomPotager: null, zones: const []);
    }

    final parcellesPotager = await parcelles.obtenirParPotager(potager.id);
    final parcellesAvecTache = await _parcellesAvecTacheDuJour(taches, maintenant);

    final zones = <ZonePotager>[];
    for (final parcelle in parcellesPotager) {
      zones.add(
        ZonePotager(
          id: parcelle.id,
          nom: parcelle.nom,
          type: parcelle.type,
          surfaceM2: parcelle.surface.enMetresCarres,
          exposition: parcelle.exposition,
          cultures: await _culturesActives(parcelle, plantations, fiches),
          aTacheAujourdhui: parcellesAvecTache.contains(parcelle.id),
        ),
      );
    }

    return PotagerVue(potagerId: potager.id, nomPotager: potager.nom, zones: zones);
  }

  /// Active crops of [parcelle] (plantation id + catalogue-resolved name).
  ///
  /// Plantations are loaded from their own repository: the `Parcelle` entity is
  /// hydrated shallowly (its `plantations` field is always empty), so reading it
  /// would never surface a freshly created plantation.
  Future<List<CulturePotager>> _culturesActives(
    Parcelle parcelle,
    AbstractPlantationRepository plantations,
    AbstractFichePlanteRepository fiches,
  ) async {
    final cultures = <CulturePotager>[];
    for (final plantation in await plantations.obtenirParParcelle(parcelle.id)) {
      if (plantation.statut.estTerminal) continue;
      final fiche = await fiches.obtenirParId(plantation.planteId);
      if (fiche != null) {
        cultures.add(CulturePotager(
          plantationId: plantation.id,
          nom: fiche.nomLocalise(_locale),
        ));
      }
    }
    return cultures;
  }

  /// Ids of the parcelles that have a task due today.
  Future<Set<String>> _parcellesAvecTacheDuJour(
    AbstractTacheRepository taches,
    DateTime Function() maintenant,
  ) async {
    final n = maintenant();
    final debut = DateTime(n.year, n.month, n.day);
    final tachesDuJour =
        await taches.obtenirEntreDates(debut, debut.add(const Duration(days: 1)));
    return {
      for (final Tache t in tachesDuJour)
        if (t.cible == CibleTache.parcelle && !t.estFaite) t.cibleId,
    };
  }
}

/// The Potager zone-list view-model provider.
final potagerProvider =
    AsyncNotifierProvider<PotagerNotifier, PotagerVue>(PotagerNotifier.new);
