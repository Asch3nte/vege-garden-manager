import 'package:riverpod/riverpod.dart';

import '../../domain/entities/famille_botanique.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/charge_tuteur.dart';
import '../../domain/enums/critere_association.dart';
import '../../domain/enums/enracinement_plante.dart';
import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/niveau_besoin.dart';
import '../../domain/enums/niveau_confiance.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/sens_association.dart';
import '../../domain/enums/sous_type_legume.dart';
import '../../domain/enums/type_benefice_association.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/type_conflit_association.dart';
import '../../domain/enums/usage_plante.dart';
import '../../domain/value_objects/periode.dart';
import '../../domain/value_objects/periodes_culture.dart';
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

  /// A companion is "notably shorter" for layering when its max height is at most
  /// this fraction of the tall plant's (ADR-0014 — étagement précis).
  static const double ratioEtagement = 0.5;

  /// Planting distance (cm) at/above which a plant counts as "spreading", for the
  /// space-competition rule (ADR-0014).
  static const int seuilEtaleeCm = 70;

  /// Benefit mechanisms the engine has a derivation rule for (ADR-0017).
  ///
  /// This is the engine's **own rule inventory** — the single source the
  /// glossary derives each mechanism page's provenance from ("computed by the
  /// engine" vs "documented by the permaculture community"), never copied by
  /// hand. A source-scan test keeps it in sync with the rules of [deriver]:
  /// adding/removing a rule without updating this set breaks the suite.
  static const Set<TypeBeneficeAssociation> beneficesDerivables = {
    TypeBeneficeAssociation.fixationAzote,
    TypeBeneficeAssociation.attractionPollinisateurs,
    TypeBeneficeAssociation.tuteurStructurel,
    TypeBeneficeAssociation.etagementLumiere,
    TypeBeneficeAssociation.successionTemporelle,
    TypeBeneficeAssociation.couvreSol,
    TypeBeneficeAssociation.briseVent,
    TypeBeneficeAssociation.brouillageOlfactif,
    TypeBeneficeAssociation.repulsionRavageur,
    TypeBeneficeAssociation.plantePiege,
    TypeBeneficeAssociation.attractionAuxiliaires,
    TypeBeneficeAssociation.ameublissementSol,
  };

  /// Conflict mechanisms the engine has a derivation rule for (ADR-0017).
  ///
  /// Same contract as [beneficesDerivables]. Allelopathy is **curated only**
  /// (ADR-0013): no reliable trait-based rule exists, so it never appears here.
  static const Set<TypeConflitAssociation> conflitsDerivables = {
    TypeConflitAssociation.memeFamilleRavageurs,
    TypeConflitAssociation.competitionLumiere,
    TypeConflitAssociation.competitionAzote,
    TypeConflitAssociation.competitionEau,
    TypeConflitAssociation.competitionEspace,
    TypeConflitAssociation.partageMaladies,
  };

  /// Every association the engine can infer for the ordered pair [a] → [b]
  /// ("grow [b] near [a]"). Empty when [a] == [b]. Family-dependent rules need
  /// [familles]; the others rely on [a]/[b] traits only.
  List<SuggestionAssociation> deriver(
    FichePlante a,
    FichePlante b, {
    ResolveurFamille? familles,
    Hemisphere? hemisphere,
    TypeClimat? climat,
  }) {
    if (a.id == b.id) return const [];
    final out = <SuggestionAssociation>[];

    // — Bénéfices —
    if (a.fixeAzote && b.besoinAzote == NiveauBesoin.eleve) {
      out.add(_benef(b, TypeBeneficeAssociation.fixationAzote, NiveauConfiance.eleve,
          criteres: const {
            CritereAssociation.sourceFixeAzote,
            CritereAssociation.cibleGourmandeAzote,
          }));
    }
    if ((a.aUsage(UsagePlante.mellifere) || a.aUsage(UsagePlante.pollinisateur)) &&
        _entomophile(b)) {
      out.add(_benef(
          b, TypeBeneficeAssociation.attractionPollinisateurs, NiveauConfiance.moyen,
          criteres: const {
            CritereAssociation.sourceAttirePollinisateurs,
            CritereAssociation.cibleEntomophile,
          }));
    }
    if (_support(a) && b.cultureVerticale && b.chargeTuteur != ChargeTuteur.lourde) {
      out.add(_benef(b, TypeBeneficeAssociation.tuteurStructurel, NiveauConfiance.moyen,
          criteres: {
            CritereAssociation.sourceSupport,
            CritereAssociation.cibleGrimpante,
            if (_plusHaute(a, b)) CritereAssociation.sourcePlusHaute,
          }));
    }
    // Étagement (ADR-0014, précis) : [a] haute & plein soleil porte de l'ombre,
    // [b] **nettement plus basse** et qui **préfère** (confiance moyenne) ou
    // **tolère** (confiance faible — c'est sous-optimal pour elle) cette ombre.
    if (a.besoins.soleil == NiveauSoleil.pleinSoleil &&
        _haute(a) &&
        _nettementPlusBasse(a, b) &&
        (_prefereOmbre(b) || _tolereOmbre(b))) {
      final prefere = _prefereOmbre(b);
      out.add(_benef(b, TypeBeneficeAssociation.etagementLumiere,
          prefere ? NiveauConfiance.moyen : NiveauConfiance.faible,
          criteres: {
            CritereAssociation.sourceHaute,
            CritereAssociation.cibleNettementPlusBasse,
            if (prefere)
              CritereAssociation.ciblePrefereOmbre
            else
              CritereAssociation.cibleTolereOmbre,
          }));
    }
    // Succession (ADR-0014) : si l'hémisphère/climat sont connus, on vérifie le
    // **calendrier réel** (occupations du sol qui ne se chevauchent pas →
    // confiance moyenne) ; sinon repli sur l'heuristique de durée (faible).
    if (hemisphere != null &&
        climat != null &&
        _successionCalendaire(a, b, hemisphere, climat)) {
      out.add(_benef(
          b, TypeBeneficeAssociation.successionTemporelle, NiveauConfiance.moyen,
          criteres: const {CritereAssociation.occupationsDecalees}));
    } else if (_successionCompatible(a, b)) {
      out.add(_benef(
          b, TypeBeneficeAssociation.successionTemporelle, NiveauConfiance.faible,
          criteres: const {CritereAssociation.cyclesComplementaires}));
    }
    if (a.aUsage(UsagePlante.couvreSol)) {
      out.add(_benef(b, TypeBeneficeAssociation.couvreSol, NiveauConfiance.faible,
          criteres: const {CritereAssociation.sourceCouvreSol}));
    }
    if (a.aUsage(UsagePlante.briseVent)) {
      out.add(_benef(b, TypeBeneficeAssociation.briseVent, NiveauConfiance.faible,
          criteres: const {CritereAssociation.sourceBriseVent}));
    }
    if (_aromatique(a) &&
        _aromatique(b) &&
        (a.aUsage(UsagePlante.repulsif) || b.aUsage(UsagePlante.repulsif))) {
      out.add(_benef(
          b, TypeBeneficeAssociation.brouillageOlfactif, NiveauConfiance.faible,
          criteres: const {
            CritereAssociation.deuxAromatiques,
            CritereAssociation.uneRepulsive,
          }));
    }
    if (a.aUsage(UsagePlante.repulsif)) {
      final cible = _premierCommun(a.repulsifContre, _bioagresseursDe(b, familles));
      if (cible != null) {
        out.add(_benef(b, TypeBeneficeAssociation.repulsionRavageur,
            NiveauConfiance.eleve,
            slug: cible,
            criteres: const {CritereAssociation.sourceRepulsiveCible}));
      }
    }
    final piege = _premierCommun(a.piegeA, _ravageursDe(b, familles));
    if (piege != null) {
      out.add(_benef(
          b, TypeBeneficeAssociation.plantePiege, NiveauConfiance.eleve,
          slug: piege,
          criteres: const {CritereAssociation.sourcePiegeCible}));
    }
    // Attire les auxiliaires (ADR-0014) : [a] attire des prédateurs/parasitoïdes,
    // qui régulent les ravageurs auxquels la famille de [b] est sujette.
    if (a.aUsage(UsagePlante.attireAuxiliaires) &&
        _ravageursDe(b, familles).isNotEmpty) {
      out.add(_benef(b, TypeBeneficeAssociation.attractionAuxiliaires,
          NiveauConfiance.moyen,
          criteres: const {
            CritereAssociation.sourceAttireAuxiliaires,
            CritereAssociation.cibleSujetteRavageurs,
          }));
    }
    // Ameublit le sol (ADR-0014) : racine profonde/pivotante de [a] qui
    // décompacte pour la racine superficielle de [b].
    if ((a.enracinement == EnracinementPlante.pivotant ||
            a.enracinement == EnracinementPlante.profond) &&
        b.enracinement == EnracinementPlante.superficiel) {
      out.add(_benef(b, TypeBeneficeAssociation.ameublissementSol,
          NiveauConfiance.moyen,
          criteres: const {
            CritereAssociation.sourceRacineProfonde,
            CritereAssociation.cibleRacineSuperficielle,
          }));
    }

    // — Conflits —
    if (_memeFamille(a, b)) {
      out.add(_conflit(
          b, TypeConflitAssociation.memeFamilleRavageurs, NiveauConfiance.eleve,
          criteres: const {CritereAssociation.memeFamille}));
    }
    // Concurrence lumière (ADR-0014, précis) : toutes deux **exigent** le plein
    // soleil (pas seulement le tolèrent) et sont hautes → elles se font de l'ombre.
    if (_exigePleinSoleil(a) && _exigePleinSoleil(b) && _haute(a) && _haute(b)) {
      out.add(_conflit(
          b, TypeConflitAssociation.competitionLumiere, NiveauConfiance.moyen,
          criteres: const {CritereAssociation.deuxHautesPleinSoleil}));
    }
    if (a.besoinAzote == NiveauBesoin.eleve && b.besoinAzote == NiveauBesoin.eleve) {
      out.add(_conflit(
          b, TypeConflitAssociation.competitionAzote, NiveauConfiance.moyen,
          criteres: const {CritereAssociation.deuxGourmandesAzote}));
    }
    // Concurrence eau (ADR-0014) : deux forts besoins en eau.
    if (a.besoins.eau == BesoinEau.eleve && b.besoins.eau == BesoinEau.eleve) {
      out.add(_conflit(b, TypeConflitAssociation.competitionEau, NiveauConfiance.moyen,
          criteres: const {CritereAssociation.deuxAssoiffees}));
    }
    // Concurrence espace (ADR-0014) : deux plantes très étalées (gros espacement).
    if (a.espacementCm >= seuilEtaleeCm && b.espacementCm >= seuilEtaleeCm) {
      out.add(_conflit(
          b, TypeConflitAssociation.competitionEspace, NiveauConfiance.moyen,
          criteres: const {CritereAssociation.deuxEtalees}));
    }
    // Maladies partagées (ADR-0014) : familles **différentes** mais hôtes d'une
    // même maladie (sinon c'est déjà « même famille »).
    if (!_memeFamille(a, b)) {
      final commune =
          _premierCommun(_maladiesDe(a, familles), _maladiesDe(b, familles));
      if (commune != null) {
        out.add(_conflit(
            b, TypeConflitAssociation.partageMaladies, NiveauConfiance.moyen,
            criteres: const {CritereAssociation.maladieCommune}));
      }
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
    Hemisphere? hemisphere,
    TypeClimat? climat,
  }) {
    final out = <SuggestionAssociation>[];
    for (final autre in catalogue) {
      if (autre.id == centre.id) continue;
      // Both directions; relabel the b→centre ones onto `autre`.
      final brutes = [
        ...deriver(centre, autre,
            familles: familles, hemisphere: hemisphere, climat: climat),
        for (final s in deriver(autre, centre,
            familles: familles, hemisphere: hemisphere, climat: climat))
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
    Set<CritereAssociation> criteres = const {},
  }) =>
      SuggestionBenefique(
          cibleId: b.id,
          mecanisme: m,
          confiance: c,
          slug: slug,
          criteres: criteres);

  SuggestionConflit _conflit(
    FichePlante b,
    TypeConflitAssociation m,
    NiveauConfiance c, {
    Set<CritereAssociation> criteres = const {},
  }) =>
      SuggestionConflit(
          cibleId: b.id, mecanisme: m, confiance: c, criteres: criteres);

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
              slug: slug,
              criteres: s.criteres),
        SuggestionConflit(:final mecanisme, :final confiance, :final slug) =>
          SuggestionConflit(
              cibleId: cibleId,
              mecanisme: mecanisme,
              confiance: confiance,
              sens: SensAssociation.recoit,
              slug: slug,
              criteres: s.criteres),
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
    // Union the evidence of both directions so the explanation stays complete.
    final criteres = {...a.criteres, ...b.criteres};
    return switch (meilleure) {
      SuggestionBenefique(:final cibleId, :final mecanisme, :final confiance, :final slug) =>
        SuggestionBenefique(
            cibleId: cibleId,
            mecanisme: mecanisme,
            confiance: confiance,
            sens: sens,
            slug: slug,
            criteres: criteres),
      SuggestionConflit(:final cibleId, :final mecanisme, :final confiance, :final slug) =>
        SuggestionConflit(
            cibleId: cibleId,
            mecanisme: mecanisme,
            confiance: confiance,
            sens: sens,
            slug: slug,
            criteres: criteres),
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

  /// The plant **prefers** shade (its optimum, not just a tolerance).
  bool _prefereOmbre(FichePlante f) =>
      f.besoins.soleil == NiveauSoleil.miOmbre ||
      f.besoins.soleil == NiveauSoleil.ombre;

  /// The plant truly **requires** full sun (optimum full sun and not shade-tolerant).
  bool _exigePleinSoleil(FichePlante f) =>
      f.besoins.soleil == NiveauSoleil.pleinSoleil && !_tolereOmbre(f);

  /// [b] is notably shorter than [a] (both heights known, ADR-0014).
  bool _nettementPlusBasse(FichePlante a, FichePlante b) {
    final ha = a.hauteurAdulteCmMax, hb = b.hauteurAdulteCmMax;
    return ha != null && hb != null && hb <= ha * ratioEtagement;
  }

  /// [a] is taller than [b] (both heights known) — a sturdier support.
  bool _plusHaute(FichePlante a, FichePlante b) {
    final ha = a.hauteurAdulteCmMax, hb = b.hauteurAdulteCmMax;
    return ha != null && hb != null && ha > hb;
  }

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

  /// Calendar succession (ADR-0014) : both plants have a soil-occupation window
  /// for [hemisphere]×[climat] and those windows **don't overlap** (one frees the
  /// spot before the other takes it).
  bool _successionCalendaire(
      FichePlante a, FichePlante b, Hemisphere hemisphere, TypeClimat climat) {
    final oa = _occupationMois(a.periodesPour(hemisphere, climat));
    final ob = _occupationMois(b.periodesPour(hemisphere, climat));
    return oa.isNotEmpty && ob.isNotEmpty && oa.intersection(ob).isEmpty;
  }

  /// The set of months a plant occupies the ground, from its earliest
  /// planting/sowing to the end of harvest; empty when not derivable.
  Set<int> _occupationMois(PeriodesCulture? p) {
    if (p == null) return const {};
    final debut = p.plantation ?? p.semisExterieur ?? p.semisInterieur;
    final fin = p.recolte;
    if (debut == null || fin == null) return const {};
    final occ = Periode(debut.moisDebut, fin.moisFin);
    return {for (var m = 1; m <= 12; m++) if (occ.contientMois(m)) m};
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

  Set<String> _maladiesDe(FichePlante f, ResolveurFamille? familles) =>
      familles?.call(f.familleBotanique)?.maladiesCommunes ?? const {};

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
