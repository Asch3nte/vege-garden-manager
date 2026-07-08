import 'package:riverpod/riverpod.dart';

import '../../domain/entities/famille_botanique.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/type_parcelle.dart';
import '../engine/evaluation_rotation.dart';
import '../engine/resultat_rotation.dart';
import '../providers/horloge_provider.dart';
import '../providers/repository_providers.dart';

/// A botanical family that grew on the plot recently, for the "what grew here"
/// readout. Deduplicated to the most recent culture of each family.
class CultureRecenteRotation {
  /// Normalized family slug.
  final String familleSlug;

  /// Localized family name when a family sheet exists, else `null` (the UI then
  /// falls back to the slug). Resolved in French — locale-aware labels are the
  /// noted i18n follow-up.
  final String? nomFamille;

  /// Common name of the example plant of that family.
  final String nomPlante;

  /// Year that culture is measured from (its end year, else planting year).
  final int annee;

  const CultureRecenteRotation({
    required this.familleSlug,
    required this.nomFamille,
    required this.nomPlante,
    required this.annee,
  });
}

/// A family that cannot be replanted yet because its return delay has not
/// elapsed since it last grew here.
class FamilleBloqueeRotation {
  final String familleSlug;
  final String? nomFamille;

  /// First year the family becomes plantable again.
  final int anneeLibre;

  /// The family return delay (years) behind the block.
  final int delaiAnnees;

  const FamilleBloqueeRotation({
    required this.familleSlug,
    required this.nomFamille,
    required this.anneeLibre,
    required this.delaiAnnees,
  });
}

/// A soil-state opportunity the recent history creates: a nitrogen fixer grew
/// recently, so nitrogen-hungry crops planted next will benefit.
class OpportuniteAzoteRotation {
  /// Common name of the fixer that grew.
  final String nomPlante;

  const OpportuniteAzoteRotation(this.nomPlante);
}

/// Plot-scoped crop-rotation synthesis shown in the zone detail (rotation
/// avancée, Lot 4): what grew here recently, which families are still blocked
/// by their return delay, and the nitrogen opportunities the history leaves.
///
/// The blocked-family decision reuses [EvaluationRotation] (single source of the
/// return-delay rule): each family present is treated as a candidate — "can I
/// replant this family here?".
class SyntheseRotationZone {
  /// `false` for renewable-soil containers (rotation does not apply); the UI
  /// then hides the section entirely.
  final bool applicable;

  /// Families grown within the recency window, most recent first (deduplicated).
  final List<CultureRecenteRotation> recentes;

  /// Families still blocked by their return delay, latest free year first.
  final List<FamilleBloqueeRotation> famillesBloquees;

  /// Nitrogen opportunities left by recent fixers (deduplicated by plant).
  final List<OpportuniteAzoteRotation> opportunites;

  const SyntheseRotationZone({
    required this.applicable,
    required this.recentes,
    required this.famillesBloquees,
    required this.opportunites,
  });

  /// A neutral/empty synthesis (no applicable rotation or no history to show).
  static const SyntheseRotationZone vide = SyntheseRotationZone(
    applicable: true,
    recentes: [],
    famillesBloquees: [],
    opportunites: [],
  );

  /// Whether the section has anything worth rendering.
  bool get aQuelqueChose =>
      applicable &&
      (recentes.isNotEmpty ||
          famillesBloquees.isNotEmpty ||
          opportunites.isNotEmpty);
}

/// Container parcelle types whose renewable soil resets the rotation clock —
/// mirrors [RecommanderPlantes]/[EvaluateurRecommandations].
const Set<TypeParcelle> _typesSansRotation = {
  TypeParcelle.pot,
  TypeParcelle.jardiniere,
};

/// Computes the [SyntheseRotationZone] for a plot (`zoneId`, `type`).
///
/// Read-only: resolves the plot's plantation history to mother sheets, then
/// derives the readout. Scoped to the zone-detail screen (autoDispose family).
final syntheseRotationZoneProvider = FutureProvider.autoDispose
    .family<SyntheseRotationZone, ({String zoneId, TypeParcelle type})>(
  (ref, args) async {
    final applicable = !_typesSansRotation.contains(args.type);
    if (!applicable) {
      return const SyntheseRotationZone(
        applicable: false,
        recentes: [],
        famillesBloquees: [],
        opportunites: [],
      );
    }

    final plantationsRepo = ref.watch(plantationRepositoryProvider);
    final fichesRepo = await ref.watch(fichePlanteRepositoryProvider.future);
    final familles = await ref.watch(familleBotaniqueCacheProvider.future);
    final eval = ref.watch(evaluationRotationProvider);
    final maintenant = ref.watch(horlogeProvider)();

    final catalogue = await fichesRepo.obtenirToutes();
    final parId = {for (final f in catalogue) f.id: f};

    // Resolve the plot's plantations to (mother sheet, reference date).
    final historique = <CulturePrecedente>[];
    for (final p in await plantationsRepo.obtenirParParcelle(args.zoneId)) {
      final fiche = parId[p.planteId];
      if (fiche == null) continue; // unknown plant → never invent a family
      final mere = fiche.estVariete ? (parId[fiche.parentId] ?? fiche) : fiche;
      historique.add(CulturePrecedente(
        fiche: mere,
        dateReference: p.dateFinReelle ?? p.dateMiseEnPlace,
      ));
    }
    if (historique.isEmpty) return SyntheseRotationZone.vide;

    String? nomFamille(String slug) => familles.parId(slug)?.nomLocalise('fr');

    // Group history by normalized family.
    final parFamille = <String, List<CulturePrecedente>>{};
    for (final c in historique) {
      (parFamille[_famille(c.fiche)] ??= []).add(c);
    }

    // Blocked families — the engine decides the rule, dates give the free year.
    final bloquees = <FamilleBloqueeRotation>[];
    for (final entry in parFamille.entries) {
      final cultures = entry.value
        ..sort((a, b) => b.dateReference.compareTo(a.dateReference));
      final res = eval.evaluer(
        candidate: cultures.first.fiche,
        historique: historique,
        date: maintenant,
      );
      final conflit = res.raisons
          .where((r) => r.motif == MotifRotation.conflitFamille)
          .firstOrNull;
      if (conflit != null) {
        final delai = conflit.delaiRequis!;
        bloquees.add(FamilleBloqueeRotation(
          familleSlug: entry.key,
          nomFamille: nomFamille(entry.key),
          anneeLibre: cultures.first.dateReference.year + delai,
          delaiAnnees: delai,
        ));
      }
    }
    bloquees.sort((a, b) => b.anneeLibre.compareTo(a.anneeLibre));

    // Recency window for "grew here recently" and nitrogen opportunities.
    final seuilRecent = DateTime(
      maintenant.year - EvaluationRotation.fenetrePrecedentDefautAnnees,
      maintenant.month,
      maintenant.day,
    );

    final recentesParFamille = <String, CulturePrecedente>{};
    final opportunites = <String, OpportuniteAzoteRotation>{};
    for (final c in historique) {
      if (!c.dateReference.isAfter(seuilRecent)) continue;
      final f = _famille(c.fiche);
      final existante = recentesParFamille[f];
      if (existante == null ||
          c.dateReference.isAfter(existante.dateReference)) {
        recentesParFamille[f] = c;
      }
      if (c.fiche.fixeAzote) {
        opportunites[c.fiche.id] =
            OpportuniteAzoteRotation(c.fiche.nomLocalise('fr'));
      }
    }
    final recentes = [
      for (final e in recentesParFamille.entries)
        CultureRecenteRotation(
          familleSlug: e.key,
          nomFamille: nomFamille(e.key),
          nomPlante: e.value.fiche.nomLocalise('fr'),
          annee: e.value.dateReference.year,
        ),
    ]..sort((a, b) => b.annee.compareTo(a.annee));

    return SyntheseRotationZone(
      applicable: true,
      recentes: recentes,
      famillesBloquees: bloquees,
      opportunites: opportunites.values.toList(),
    );
  },
);

String _famille(FichePlante f) =>
    FamilleBotanique.normaliserCle(f.rotationFamille ?? f.familleBotanique);
