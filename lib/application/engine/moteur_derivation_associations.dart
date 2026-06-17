import 'package:riverpod/riverpod.dart';

import '../../domain/entities/famille_botanique.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/charge_tuteur.dart';
import '../../domain/enums/niveau_besoin.dart';
import '../../domain/enums/niveau_confiance.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/sens_association.dart';
import '../../domain/enums/sous_type_legume.dart';
import '../../domain/enums/type_benefice_association.dart';
import '../../domain/enums/type_conflit_association.dart';
import '../../domain/enums/usage_plante.dart';
import 'suggestion_association.dart';

/// Resolves a [FamilleBotanique] from a plant's raw `famille_botanique` string
/// (the engine normalises the key). Lets the rules that need a family's pests
/// (repulsion / trap) work without coupling the engine to a repository.
typedef ResolveurFamille = FamilleBotanique? Function(String familleBrute);

/// Pure engine that **derives typed companion associations** from plant traits,
/// usages and (family) bioaggressors (ADR-0010, Lot 3). It is what lets the app
/// *reason* about pairings — suggesting the milpa or tomato + marigold without
/// any pair being hand-authored — rather than only reciting curated pairs.
///
/// Stateless and dependency-free; family-dependent rules (repulsion / trap) are
/// skipped when no [ResolveurFamille] is supplied. Each suggestion carries a
/// [NiveauConfiance]; curated associations take precedence over derived ones
/// (see [suggestionsNouvelles]).
class MoteurDerivationAssociations {
  const MoteurDerivationAssociations();

  /// Height (cm) at/above which a plant counts as "tall" (shade-caster, sturdy
  /// support, light competitor).
  static const int seuilHauteCm = 150;

  /// Days at/below which a crop counts as "short cycle" (succession).
  static const int seuilCourtJours = 60;

  /// Days at/above which a crop counts as "long cycle" (succession).
  static const int seuilLongJours = 100;

  /// Every association the engine can infer for the ordered pair [a] → [b]
  /// ("grow [b] near [a]"). Empty when [a] == [b]. Family-dependent rules need
  /// [familles]; the others rely on [a]/[b] traits only.
  List<SuggestionAssociation> deriver(
    FichePlante a,
    FichePlante b, {
    ResolveurFamille? familles,
  }) {
    if (a.id == b.id) return const [];
    final out = <SuggestionAssociation>[];

    // — Bénéfices —
    if (a.fixeAzote && b.besoinAzote == NiveauBesoin.eleve) {
      out.add(_benef(b, TypeBeneficeAssociation.fixationAzote, NiveauConfiance.eleve));
    }
    if ((a.aUsage(UsagePlante.mellifere) || a.aUsage(UsagePlante.pollinisateur)) &&
        _entomophile(b)) {
      out.add(_benef(
          b, TypeBeneficeAssociation.attractionPollinisateurs, NiveauConfiance.moyen));
    }
    if (_support(a) && b.cultureVerticale && b.chargeTuteur != ChargeTuteur.lourde) {
      out.add(_benef(b, TypeBeneficeAssociation.tuteurStructurel, NiveauConfiance.moyen));
    }
    if (a.besoins.soleil == NiveauSoleil.pleinSoleil &&
        _haute(a) &&
        _tolereOmbre(b)) {
      out.add(_benef(b, TypeBeneficeAssociation.etagementLumiere, NiveauConfiance.moyen));
    }
    if (_successionCompatible(a, b)) {
      out.add(_benef(
          b, TypeBeneficeAssociation.successionTemporelle, NiveauConfiance.faible));
    }
    if (a.aUsage(UsagePlante.couvreSol)) {
      out.add(_benef(b, TypeBeneficeAssociation.couvreSol, NiveauConfiance.faible));
    }
    if (a.aUsage(UsagePlante.briseVent)) {
      out.add(_benef(b, TypeBeneficeAssociation.briseVent, NiveauConfiance.faible));
    }
    if (_aromatique(a) &&
        _aromatique(b) &&
        (a.aUsage(UsagePlante.repulsif) || b.aUsage(UsagePlante.repulsif))) {
      out.add(_benef(
          b, TypeBeneficeAssociation.brouillageOlfactif, NiveauConfiance.faible));
    }
    if (a.aUsage(UsagePlante.repulsif)) {
      final cible = _premierCommun(a.repulsifContre, _bioagresseursDe(b, familles));
      if (cible != null) {
        out.add(_benef(b, TypeBeneficeAssociation.repulsionRavageur,
            NiveauConfiance.eleve, slug: cible));
      }
    }
    final piege = _premierCommun(a.piegeA, _ravageursDe(b, familles));
    if (piege != null) {
      out.add(_benef(
          b, TypeBeneficeAssociation.plantePiege, NiveauConfiance.eleve, slug: piege));
    }

    // — Conflits —
    if (_memeFamille(a, b)) {
      out.add(_conflit(
          b, TypeConflitAssociation.memeFamilleRavageurs, NiveauConfiance.eleve));
    }
    if (a.besoins.soleil == NiveauSoleil.pleinSoleil &&
        b.besoins.soleil == NiveauSoleil.pleinSoleil &&
        _haute(a) &&
        _haute(b)) {
      out.add(_conflit(
          b, TypeConflitAssociation.competitionLumiere, NiveauConfiance.moyen));
    }
    if (a.besoinAzote == NiveauBesoin.eleve && b.besoinAzote == NiveauBesoin.eleve) {
      out.add(_conflit(
          b, TypeConflitAssociation.competitionAzote, NiveauConfiance.moyen));
    }
    return out;
  }

  /// New suggestions for [centre] across [catalogue], in **either** direction
  /// (relabelled to the other plant), with curated associations taking
  /// precedence: a pair already curated good (resp. to-avoid) yields **no**
  /// derived benefit (resp. conflict). Per (target, sense, mechanism) only the
  /// highest-confidence suggestion is kept.
  List<SuggestionAssociation> suggestionsNouvelles(
    FichePlante centre,
    Iterable<FichePlante> catalogue, {
    ResolveurFamille? familles,
  }) {
    final out = <SuggestionAssociation>[];
    for (final autre in catalogue) {
      if (autre.id == centre.id) continue;
      // Both directions; relabel the b→centre ones onto `autre`.
      final brutes = [
        ...deriver(centre, autre, familles: familles),
        for (final s in deriver(autre, centre, familles: familles))
          _relabel(s, autre.id),
      ];
      final curatedBenef = centre.sAssocieBienAvec(autre.id);
      final curatedConflit = centre.entreEnConflitAvec(autre.id);

      // Keep one per mechanism, combining the two directions into a sens
      // (donne + recoit → mutuel) and keeping the highest confidence; drop the
      // sense that is curated.
      final meilleures = <String, SuggestionAssociation>{};
      for (final s in brutes) {
        if (s is SuggestionBenefique && curatedBenef) continue;
        if (s is SuggestionConflit && curatedConflit) continue;
        final cle = switch (s) {
          SuggestionBenefique(:final mecanisme) => 'b_${mecanisme.name}',
          SuggestionConflit(:final mecanisme) => 'c_${mecanisme.name}',
        };
        final existante = meilleures[cle];
        meilleures[cle] =
            existante == null ? s : _fusionner(existante, s);
      }
      out.addAll(meilleures.values);
    }
    return out;
  }

  // --- Rule helpers -------------------------------------------------------

  SuggestionBenefique _benef(
    FichePlante b,
    TypeBeneficeAssociation m,
    NiveauConfiance c, {
    String? slug,
  }) =>
      SuggestionBenefique(cibleId: b.id, mecanisme: m, confiance: c, slug: slug);

  SuggestionConflit _conflit(
          FichePlante b, TypeConflitAssociation m, NiveauConfiance c) =>
      SuggestionConflit(cibleId: b.id, mecanisme: m, confiance: c);

  /// Relabels a `deriver(autre, centre)` suggestion onto [cibleId] and flips its
  /// direction to [SensAssociation.recoit] (the centre *receives* the service).
  SuggestionAssociation _relabel(SuggestionAssociation s, String cibleId) =>
      switch (s) {
        SuggestionBenefique(:final mecanisme, :final confiance, :final slug) =>
          SuggestionBenefique(
              cibleId: cibleId,
              mecanisme: mecanisme,
              confiance: confiance,
              sens: SensAssociation.recoit,
              slug: slug),
        SuggestionConflit(:final mecanisme, :final confiance, :final slug) =>
          SuggestionConflit(
              cibleId: cibleId,
              mecanisme: mecanisme,
              confiance: confiance,
              sens: SensAssociation.recoit,
              slug: slug),
      };

  /// Merges two suggestions for the same (target, mechanism): combines their
  /// directions (donne + recoit → mutuel) and keeps the higher-confidence one's
  /// fields.
  SuggestionAssociation _fusionner(
    SuggestionAssociation a,
    SuggestionAssociation b,
  ) {
    final sens = a.sens.combiner(b.sens);
    final meilleure = b.confiance.index > a.confiance.index ? b : a;
    return switch (meilleure) {
      SuggestionBenefique(:final cibleId, :final mecanisme, :final confiance, :final slug) =>
        SuggestionBenefique(
            cibleId: cibleId,
            mecanisme: mecanisme,
            confiance: confiance,
            sens: sens,
            slug: slug),
      SuggestionConflit(:final cibleId, :final mecanisme, :final confiance, :final slug) =>
        SuggestionConflit(
            cibleId: cibleId,
            mecanisme: mecanisme,
            confiance: confiance,
            sens: sens,
            slug: slug),
    };
  }

  bool _haute(FichePlante f) =>
      f.hauteurAdulteCmMax != null && f.hauteurAdulteCmMax! >= seuilHauteCm;

  /// A plant whose flowers benefit from insect pollination (approximation).
  bool _entomophile(FichePlante f) =>
      f.categorie == CategoriePlante.fruit ||
      f.categorie == CategoriePlante.petitFruit ||
      f.sousType == SousTypeLegume.legumeFruit;

  /// A sturdy living support: an explicit living stake, or a tall non-climber.
  bool _support(FichePlante f) =>
      f.aUsage(UsagePlante.tuteurVivant) || (_haute(f) && !f.cultureVerticale);

  bool _tolereOmbre(FichePlante f) =>
      f.besoins.soleilMin == NiveauSoleil.miOmbre ||
      f.besoins.soleilMin == NiveauSoleil.ombre;

  bool _aromatique(FichePlante f) =>
      f.categorie == CategoriePlante.aromatique ||
      f.aUsage(UsagePlante.condimentaire);

  bool _successionCompatible(FichePlante a, FichePlante b) {
    final aCourt = a.dureeAvantRecolteJoursMax <= seuilCourtJours;
    final aLong = a.dureeAvantRecolteJoursMin >= seuilLongJours;
    final bCourt = b.dureeAvantRecolteJoursMax <= seuilCourtJours;
    final bLong = b.dureeAvantRecolteJoursMin >= seuilLongJours;
    return (aCourt && bLong) || (aLong && bCourt);
  }

  bool _memeFamille(FichePlante a, FichePlante b) =>
      FamilleBotanique.normaliserCle(a.familleBotanique) ==
      FamilleBotanique.normaliserCle(b.familleBotanique);

  Set<String> _bioagresseursDe(FichePlante f, ResolveurFamille? familles) {
    final fam = familles?.call(f.familleBotanique);
    if (fam == null) return const {};
    return {...fam.maladiesCommunes, ...fam.ravageursCommuns};
  }

  Set<String> _ravageursDe(FichePlante f, ResolveurFamille? familles) =>
      familles?.call(f.familleBotanique)?.ravageursCommuns ?? const {};

  String? _premierCommun(Set<String> a, Set<String> b) {
    for (final s in a) {
      if (b.contains(s)) return s;
    }
    return null;
  }
}

/// DI provider for the (stateless) [MoteurDerivationAssociations].
final moteurDerivationAssociationsProvider =
    Provider<MoteurDerivationAssociations>(
  (ref) => const MoteurDerivationAssociations(),
);
