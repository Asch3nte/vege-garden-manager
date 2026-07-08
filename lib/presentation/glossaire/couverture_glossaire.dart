import '../../domain/enums/technique_sol.dart';
import '../../domain/enums/type_benefice_association.dart';
import '../../domain/enums/type_conflit_association.dart';
import '../../domain/enums/type_equipement.dart';
import 'catalogue/notions_associations.dart';
import 'catalogue/notions_sol.dart';
import 'catalogue/outils.dart';
import 'terme_glossaire.dart';

/// Coverage map of the glossary (ADR-0017, D6).
///
/// Every enum declared under `lib/domain/enums/` must be **either** covered —
/// listed here with the id(s) of the glossary term(s) that explain it — **or**
/// consciously excluded ([enumsExclus]). The glossary integrity test scans the
/// enum source files and fails on any enum missing from both lists, and on any
/// listed id that does not resolve in the built glossary: adding a business
/// enum without its glossary entry breaks CI.
///
/// Keys are the Dart enum names exactly as declared.
final Map<String, List<String>> enumsCouverts = Map.unmodifiable({
  // — Cultures & plantes —
  'CategoriePlante': [TermeGlossaire.idNotion('categorie-plante')],
  'SousTypeLegume': [TermeGlossaire.idNotion('sous-type-legume')],
  'UsagePlante': [TermeGlossaire.idNotion('usage-plante')],
  'StadeCroissance': [TermeGlossaire.idNotion('stade-croissance')],
  'MethodeMiseEnPlace': [TermeGlossaire.idNotion('methode-mise-en-place')],
  'StatutPlantation': [TermeGlossaire.idNotion('statut-plantation')],
  'RaisonReco': [TermeGlossaire.idNotion('pourquoi-recommandation')],
  // Functional crop groups used as rotation precedents (legumes, green manures)
  // — explained by the crop-rotation page. Dedicated per-value labels/pages are
  // tracked as the rotation avancée i18n follow-up (Lot 4).
  'GroupeCultural': [TermeGlossaire.idNotion('rotation-cultures')],

  // — Santé du jardin —
  'TypeBioagresseur': [TermeGlossaire.idNotion('bioagresseur')],

  // — Sol & terre — (textures & techniques: one page per value, D1)
  'TextureSol': [
    TermeGlossaire.idNotion('texture-sol'),
    TermeGlossaire.idNotion('sol-argileux'),
    TermeGlossaire.idNotion('sol-sableux'),
    TermeGlossaire.idNotion('sol-limoneux'),
    TermeGlossaire.idNotion('sol-calcaire'),
    TermeGlossaire.idNotion('sol-humifere'),
    TermeGlossaire.idNotion('sol-tourbeux'),
    TermeGlossaire.idNotion('sol-caillouteux'),
  ],
  'PhSol': [TermeGlossaire.idNotion('ph-sol')],
  'QualiteSol': [TermeGlossaire.idNotion('qualite-sol')],
  'SourceTypeSol': [TermeGlossaire.idNotion('source-type-sol')],
  'TechniqueSol': [
    TermeGlossaire.idNotion('techniques-sol'),
    for (final v in TechniqueSol.values) idTechnique(v),
  ],
  'EnracinementPlante': [TermeGlossaire.idNotion('enracinement')],
  'NiveauBesoin': [TermeGlossaire.idNotion('besoin-nutriments')],

  // — Eau & arrosage —
  'BesoinEau': [TermeGlossaire.idNotion('besoin-eau')],
  'UrgenceArrosage': [TermeGlossaire.idNotion('urgence-arrosage')],
  'ToleranceSecheresse': [TermeGlossaire.idNotion('tolerance-secheresse')],
  // Water-sensitive growth stages are a facet of the detailed water need
  // (ADR-0009 `acces.eauDetaillee`); the detailed-watering section links there.
  'PhaseSensibleEau': [TermeGlossaire.idNotion('besoin-eau')],

  // — Outils & équipements — (one page per value; `autre` names nothing)
  'TypeEquipement': [
    for (final v in TypeEquipement.values)
      if (v != TypeEquipement.autre) idOutilEquipement(v),
  ],
  'EtatEquipement': [TermeGlossaire.idNotion('etat-equipement')],
  'ChargeTuteur': [TermeGlossaire.idOutil('tuteur')],

  // — Climat & saisons —
  'TypeClimat': [TermeGlossaire.idNotion('type-climat')],
  'ZoneRusticite': [TermeGlossaire.idNotion('zone-rusticite')],
  'Hemisphere': [TermeGlossaire.idNotion('hemisphere-saisons')],
  'TypeAlerteMeteo': [TermeGlossaire.idNotion('alertes-meteo')],
  'EtatCielJour': [TermeGlossaire.idNotion('etat-ciel')],
  'NiveauSoleil': [TermeGlossaire.idNotion('exposition')],

  // — Associations & compagnonnage — (one page per mechanism)
  'TypeBeneficeAssociation': [
    for (final m in TypeBeneficeAssociation.values) idMecanismeBenefice(m),
  ],
  'TypeConflitAssociation': [
    for (final m in TypeConflitAssociation.values) idMecanismeConflit(m),
  ],
  'FamilleEffetAssociation': [TermeGlossaire.idNotion('familles-effets')],
  'FamilleEffetConflit': [TermeGlossaire.idNotion('familles-effets')],
  'SensAssociation': [TermeGlossaire.idNotion('sens-association')],
  'NiveauConfiance': [TermeGlossaire.idNotion('niveau-confiance')],
  'PoidsAssociation': [TermeGlossaire.idNotion('ponderation-associations')],
  // The criteria vocabulary is explained by the general "how the app computes
  // associations" page; each criterion line already shows its real values in
  // the associations view (ADR-0014).
  'CritereAssociation': [TermeGlossaire.idNotion('calcul-associations')],

  // — Gestes & organisation —
  'TypeTache': [TermeGlossaire.idNotion('types-taches')],
  'PrioriteTache': [TermeGlossaire.idNotion('priorite-tache')],
  'TypeRecurrence': [TermeGlossaire.idNotion('recurrence')],
  'DestinationRecolte': [TermeGlossaire.idNotion('destination-recolte')],
  'QualiteRecolte': [TermeGlossaire.idNotion('qualite-recolte')],
  'UniteQuantite': [TermeGlossaire.idNotion('unites-quantite')],
  'TypeObservation': [TermeGlossaire.idNotion('types-observations')],
  'GraviteObservation': [TermeGlossaire.idNotion('gravite-observation')],
  'TypeParcelle': [TermeGlossaire.idNotion('types-parcelles')],
  'TypeEmplacement': [TermeGlossaire.idNotion('types-emplacements')],
  'NiveauExperience': [TermeGlossaire.idNotion('niveaux-experience')],
});

/// Enums consciously **excluded** from the glossary (D6): pure UI/device
/// mechanics with no gardening meaning to explain. This list is the only
/// escape hatch — an enum absent from both lists breaks the integrity test,
/// so every exclusion is a documented decision.
const Set<String> enumsExclus = {
  // Interface preferences (settings screen wording is self-explanatory).
  'SensSwipe', // list swipe direction
  'ThemeApp', // light/dark/auto
  'Langue', // interface language
  'SystemeUnites', // metric/imperial
  // Import/export & reminder plumbing.
  'ModeImport', // merge/replace during a JSON import
  'EtatRappel', // reminder lifecycle (scheduled/fired…)
  'EtatTache', // task lifecycle (todo/done…), visible as checkboxes
  'JourSemaine', // weekday enumeration
  // Weather/location plumbing.
  'TypeReleveMeteo', // raw reading kind of the weather cache
  'PermissionLocalisation', // OS permission state
  'SourceLocalisation', // GPS vs manual pick
  'ModeGeolocalisation', // settings chip (off/manual/gps)
  // Polymorphic target discriminators (technical tagging of links).
  'CibleTache',
  'CibleObservation',
  // Unit conversion internals (the user-facing page covers UniteQuantite).
  'NatureUnite',
};
