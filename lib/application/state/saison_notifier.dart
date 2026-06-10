import 'package:riverpod/riverpod.dart';

import '../../domain/enums/statut_plantation.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../providers/repository_providers.dart';
import 'contexte_climat.dart';
import 'saison_vue.dart';

/// Locale used to resolve plant display names (French-first app).
const String _locale = 'fr';

/// Assembles the **Saison** view-model: the active garden's cultivated plants
/// with their sowing/planting/harvest windows, resolved for the garden's
/// hemisphere × climate.
///
/// Composition only. The hemisphere is derived from the garden's position
/// (latitude sign); when there is no position the northern hemisphere is
/// **assumed and flagged** ([SaisonVue.hemisphereSuppose]) rather than silently
/// defaulted. The climate is the garden's declared [TypeClimat]. A plant with no
/// period data for that pair still appears, with empty windows.
class SaisonNotifier extends AsyncNotifier<SaisonVue> {
  @override
  Future<SaisonVue> build() async {
    final potagers = ref.watch(potagerRepositoryProvider);
    final parcelles = ref.watch(parcelleRepositoryProvider);
    final plantations = ref.watch(plantationRepositoryProvider);
    final fiches = await ref.watch(fichePlanteRepositoryProvider.future);
    return _assembler(potagers, parcelles, plantations, fiches);
  }

  Future<SaisonVue> _assembler(
    AbstractPotagerRepository potagers,
    AbstractParcelleRepository parcelles,
    AbstractPlantationRepository plantations,
    AbstractFichePlanteRepository fiches,
  ) async {
    final potager = await potagers.obtenirPotagerActif();
    if (potager == null) return SaisonVue.sansContexte();

    final contexte = ContexteClimat.pour(potager);

    // Distinct active plants across the garden's parcelles.
    final planteIds = <String>{};
    for (final parcelle in await parcelles.obtenirParPotager(potager.id)) {
      for (final p in await plantations.obtenirParParcelle(parcelle.id)) {
        if (!p.statut.estTerminal) planteIds.add(p.planteId);
      }
    }

    final lignes = <LigneSaison>[];
    for (final id in planteIds) {
      final fiche = await fiches.obtenirParId(id);
      if (fiche == null) continue;
      final pc = fiche.periodesPour(contexte.hemisphere, contexte.climat);
      lignes.add(LigneSaison(
        nom: fiche.nomLocalise(_locale),
        // Prefer the outdoor sowing window; fall back to indoor sowing.
        semis: pc?.semisExterieur ?? pc?.semisInterieur,
        plantation: pc?.plantation,
        recolte: pc?.recolte,
      ));
    }
    lignes.sort((a, b) => a.nom.compareTo(b.nom));

    return SaisonVue(
      hemisphereSuppose: contexte.hemisphereSuppose,
      lignes: lignes,
    );
  }
}

/// The Saison view-model provider.
final saisonProvider =
    AsyncNotifierProvider<SaisonNotifier, SaisonVue>(SaisonNotifier.new);
