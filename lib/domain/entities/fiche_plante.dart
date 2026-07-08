import '../enums/categorie_plante.dart';
import '../enums/tolerance_secheresse.dart';
import '../enums/charge_tuteur.dart';
import '../enums/enracinement_plante.dart';
import '../enums/hemisphere.dart';
import '../enums/niveau_besoin.dart';
import '../enums/sous_type_legume.dart';
import '../enums/type_climat.dart';
import '../enums/type_parcelle.dart';
import '../enums/usage_plante.dart';
import '../enums/zone_rusticite.dart';
import '../value_objects/association_benefique.dart';
import '../value_objects/association_conflit.dart';
import '../value_objects/besoins_culture.dart';
import '../value_objects/periodes_culture.dart';
import '../value_objects/precedent_cultural.dart';

/// Reference sheet for a species/variety, loaded from the YAML catalogue and
/// **not created by the user**. Multilingual by design (localised names),
/// associations expressed by plant `id`, planting periods indexed by hemisphere
/// then climate.
///
/// `FichePlante` is an immutable catalogue **entity** (identity by [id]; the id
/// is the YAML `id:`, snake_case). Domain names are kept in French; the code is
/// documented in English. See `docs/05-modele-de-domaine.md` §3.6.
class FichePlante {
  final String _id;
  // Parent species id when this sheet is a variety (cultivar); `null` on a
  // mother sheet (species level). See ADR-0005.
  final String? _parentId;
  final String _nomScientifique;
  final String _familleBotanique;
  final CategoriePlante _categorie;
  final SousTypeLegume? _sousType;
  final Set<UsagePlante> _usages;
  final Map<String, String> _nomsLocalises;
  final BesoinsCulture _besoins;
  final int _espacementCm;
  final int _dureeAvantRecolteJoursMin;
  final int _dureeAvantRecolteJoursMax;
  final Map<Hemisphere, Map<TypeClimat, PeriodesCulture>> _periodes;
  final List<AssociationBenefique> _associationsBenefiques;
  final List<AssociationConflit> _associationsNegatives;
  final String? _rotationFamille;
  final int? _delaiRetourAnnees;
  // Rotation avancée (Lot 1) — typed cultural precedents (families or
  // functional groups). Empty when the sheet declares none.
  final Set<PrecedentCultural> _precedentsFavorables;
  final Set<PrecedentCultural> _precedentsDefavorables;
  final Map<String, String> _descriptionsLocalisees;

  // Enrichissement §A — rusticité USDA tolérée par la plante
  final ZoneRusticite? _rusticiteMin;
  // Enrichissement §B — tolérance au gel
  final double? _temperatureMinSurvie;
  final bool _geleFatal;
  // Enrichissement §C — niveau de difficulté (1 débutant → 3 expert)
  final int? _difficulte;
  // Enrichissement §D — compatibilité contenant / profondeur sol
  final int? _profondeurSolMinCm;
  final bool _compatibleHorsSol;
  // Enrichissement §E — culture verticale (tuteur/treillis)
  final bool _cultureVerticale;
  // Enrichissement §F — hauteur adulte (cm), bornes basse/haute (optionnel)
  final int? _hauteurAdulteCmMin;
  final int? _hauteurAdulteCmMax;
  // Enrichissement §H — dynamique azotée
  final bool _fixeAzote;
  final NiveauBesoin? _besoinAzote;
  // Enrichissement ADR-0010 Lot 2 — défense ciblée & charge sur tuteur
  // Slugs Bioagresseur que la plante repousse / piège (intégrité référentielle
  // vérifiée par VerificateurIntegriteRepulsifs, comme rotation.famille).
  final Set<String> _repulsifContre;
  final Set<String> _piegeA;
  final ChargeTuteur? _chargeTuteur;
  // Enrichissement ADR-0014 — système racinaire (structuration du sol / concurrence).
  final EnracinementPlante? _enracinement;
  // Enrichissement ADR-0015 Lot 4 — réponse thermique & sécheresse
  final ToleranceSecheresse? _toleranceSecheresse;
  final double? _temperatureMaxTolerance;

  FichePlante._(
    this._id,
    this._parentId,
    this._nomScientifique,
    this._familleBotanique,
    this._categorie,
    this._sousType,
    this._usages,
    this._nomsLocalises,
    this._besoins,
    this._espacementCm,
    this._dureeAvantRecolteJoursMin,
    this._dureeAvantRecolteJoursMax,
    this._periodes,
    this._associationsBenefiques,
    this._associationsNegatives,
    this._rotationFamille,
    this._delaiRetourAnnees,
    this._precedentsFavorables,
    this._precedentsDefavorables,
    this._descriptionsLocalisees,
    this._rusticiteMin,
    this._temperatureMinSurvie,
    this._geleFatal,
    this._difficulte,
    this._profondeurSolMinCm,
    this._compatibleHorsSol,
    this._cultureVerticale,
    this._hauteurAdulteCmMin,
    this._hauteurAdulteCmMax,
    this._fixeAzote,
    this._besoinAzote,
    this._repulsifContre,
    this._piegeA,
    this._chargeTuteur,
    this._enracinement,
    this._toleranceSecheresse,
    this._temperatureMaxTolerance,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_parentId == null || _parentId.isNotEmpty,
            'parentId, when set, must not be empty'),
        assert(_parentId != _id, 'a variety cannot be its own parent'),
        assert(_nomScientifique.isNotEmpty, 'nomScientifique must not be empty'),
        assert(_familleBotanique.isNotEmpty, 'familleBotanique must not be empty'),
        assert(_usages.isNotEmpty, 'a plant must have at least one usage'),
        assert(_nomsLocalises.containsKey('fr'), 'the French name is mandatory'),
        assert(_espacementCm > 0, 'espacementCm must be > 0'),
        assert(
          _dureeAvantRecolteJoursMin > 0 &&
              _dureeAvantRecolteJoursMin <= _dureeAvantRecolteJoursMax,
          'duration must be positive with min <= max',
        ),
        assert(
          _difficulte == null || (_difficulte >= 1 && _difficulte <= 3),
          'difficulte must be 1, 2 or 3',
        );

  /// Builds a plant sheet. Collections are stored unmodifiable; periods default
  /// to empty. All enrichment fields (§A–H of doc 16) are optional.
  factory FichePlante({
    required String id,
    required String nomScientifique,
    required String familleBotanique,
    required CategoriePlante categorie,
    required Set<UsagePlante> usages,
    required Map<String, String> nomsLocalises,
    required BesoinsCulture besoins,
    required int espacementCm,
    required int dureeAvantRecolteJoursMin,
    required int dureeAvantRecolteJoursMax,
    String? parentId,
    SousTypeLegume? sousType,
    Map<Hemisphere, Map<TypeClimat, PeriodesCulture>>? periodes,
    List<AssociationBenefique>? associationsBenefiques,
    List<AssociationConflit>? associationsNegatives,
    String? rotationFamille,
    int? delaiRetourAnnees,
    Set<PrecedentCultural>? precedentsFavorables,
    Set<PrecedentCultural>? precedentsDefavorables,
    Map<String, String>? descriptionsLocalisees,
    // Enrichissement §A
    ZoneRusticite? rusticiteMin,
    // Enrichissement §B
    double? temperatureMinSurvie,
    bool geleFatal = false,
    // Enrichissement §C
    int? difficulte,
    // Enrichissement §D
    int? profondeurSolMinCm,
    bool compatibleHorsSol = true,
    // Enrichissement §E
    bool cultureVerticale = false,
    // Enrichissement §F
    int? hauteurAdulteCmMin,
    int? hauteurAdulteCmMax,
    // Enrichissement §H
    bool fixeAzote = false,
    NiveauBesoin? besoinAzote,
    // Enrichissement ADR-0010 Lot 2
    Set<String>? repulsifContre,
    Set<String>? piegeA,
    ChargeTuteur? chargeTuteur,
    // Enrichissement ADR-0014
    EnracinementPlante? enracinement,
    // Enrichissement ADR-0015 Lot 4
    ToleranceSecheresse? toleranceSecheresse,
    double? temperatureMaxTolerance,
  }) =>
      FichePlante._(
        id,
        parentId,
        nomScientifique,
        familleBotanique,
        categorie,
        sousType,
        Set<UsagePlante>.unmodifiable(usages),
        Map<String, String>.unmodifiable(nomsLocalises),
        besoins,
        espacementCm,
        dureeAvantRecolteJoursMin,
        dureeAvantRecolteJoursMax,
        _figerPeriodes(periodes ?? const {}),
        List<AssociationBenefique>.unmodifiable(
            associationsBenefiques ?? const <AssociationBenefique>[]),
        List<AssociationConflit>.unmodifiable(
            associationsNegatives ?? const <AssociationConflit>[]),
        rotationFamille,
        delaiRetourAnnees,
        Set<PrecedentCultural>.unmodifiable(
            precedentsFavorables ?? const <PrecedentCultural>{}),
        Set<PrecedentCultural>.unmodifiable(
            precedentsDefavorables ?? const <PrecedentCultural>{}),
        Map<String, String>.unmodifiable(descriptionsLocalisees ?? const {}),
        rusticiteMin,
        temperatureMinSurvie,
        geleFatal,
        difficulte,
        profondeurSolMinCm,
        compatibleHorsSol,
        cultureVerticale,
        hauteurAdulteCmMin,
        hauteurAdulteCmMax,
        fixeAzote,
        besoinAzote,
        Set<String>.unmodifiable(repulsifContre ?? const <String>{}),
        Set<String>.unmodifiable(piegeA ?? const <String>{}),
        chargeTuteur,
        enracinement,
        toleranceSecheresse,
        temperatureMaxTolerance,
      );

  static Map<Hemisphere, Map<TypeClimat, PeriodesCulture>> _figerPeriodes(
    Map<Hemisphere, Map<TypeClimat, PeriodesCulture>> p,
  ) =>
      Map<Hemisphere, Map<TypeClimat, PeriodesCulture>>.unmodifiable({
        for (final e in p.entries)
          e.key: Map<TypeClimat, PeriodesCulture>.unmodifiable(e.value),
      });

  String get id => _id;

  /// Parent species id when this sheet is a variety, else `null` (ADR-0005).
  String? get parentId => _parentId;

  /// Whether this sheet is a variety/cultivar (it inherits from a mother sheet).
  bool get estVariete => _parentId != null;

  /// Whether this sheet is a mother sheet (species level, no parent).
  bool get estMere => _parentId == null;

  String get nomScientifique => _nomScientifique;
  String get familleBotanique => _familleBotanique;
  CategoriePlante get categorie => _categorie;
  SousTypeLegume? get sousType => _sousType;
  Set<UsagePlante> get usages => _usages;
  Map<String, String> get nomsLocalises => _nomsLocalises;
  BesoinsCulture get besoins => _besoins;
  int get espacementCm => _espacementCm;
  int get dureeAvantRecolteJoursMin => _dureeAvantRecolteJoursMin;
  int get dureeAvantRecolteJoursMax => _dureeAvantRecolteJoursMax;
  String? get rotationFamille => _rotationFamille;
  int? get delaiRetourAnnees => _delaiRetourAnnees;

  /// Cultural precedents that make this plant a **good** follower (unmodifiable,
  /// possibly empty) — families or functional groups it does well after
  /// (rotation avancée). See [PrecedentCultural].
  Set<PrecedentCultural> get precedentsFavorables => _precedentsFavorables;

  /// Cultural precedents that make this plant a **poor** follower (unmodifiable,
  /// possibly empty) — typically its own family or shared-pest families.
  Set<PrecedentCultural> get precedentsDefavorables => _precedentsDefavorables;

  /// Typed beneficial associations of this plant — each pairs a target id with
  /// an optional mechanism and localised reason (unmodifiable, ADR-0010).
  List<AssociationBenefique> get associationsBenefiques =>
      _associationsBenefiques;

  /// Typed conflicting associations of this plant (unmodifiable, ADR-0010).
  List<AssociationConflit> get associationsNegatives => _associationsNegatives;

  // Enrichissement §A
  ZoneRusticite? get rusticiteMin => _rusticiteMin;
  // Enrichissement §B
  double? get temperatureMinSurvie => _temperatureMinSurvie;
  bool get geleFatal => _geleFatal;
  // Enrichissement §C
  int? get difficulte => _difficulte;
  // Enrichissement §D
  int? get profondeurSolMinCm => _profondeurSolMinCm;
  bool get compatibleHorsSol => _compatibleHorsSol;
  // Enrichissement §E
  bool get cultureVerticale => _cultureVerticale;
  // Enrichissement §F — hauteur adulte (cm)
  int? get hauteurAdulteCmMin => _hauteurAdulteCmMin;
  int? get hauteurAdulteCmMax => _hauteurAdulteCmMax;
  // Enrichissement §H
  bool get fixeAzote => _fixeAzote;
  NiveauBesoin? get besoinAzote => _besoinAzote;

  // Enrichissement ADR-0010 Lot 2
  /// Bioaggressor slugs this plant **repels** from its neighbours (unmodifiable).
  Set<String> get repulsifContre => _repulsifContre;

  /// Bioaggressor slugs this plant **traps** as a decoy (unmodifiable).
  Set<String> get piegeA => _piegeA;

  /// How heavy this plant is for a support when grown as a climber, or `null`
  /// when unspecified (the engine then approximates it).
  ChargeTuteur? get chargeTuteur => _chargeTuteur;

  /// Root system (depth/shape), or `null` when unspecified (ADR-0014). Drives
  /// the soil-loosening rule and refines root competition.
  EnracinementPlante? get enracinement => _enracinement;

  // Enrichissement ADR-0015 Lot 4
  /// Drought tolerance level, or `null` when unspecified. Used by [BilanArrosage]
  /// to scale the demand index (×0.8 forte / ×1.0 moyenne / ×1.2 faible).
  ToleranceSecheresse? get toleranceSecheresse => _toleranceSecheresse;

  /// Plant-specific heat-stress threshold (°C), or `null` when unspecified.
  /// When [tempMax] reaches this value the heatwave multiplier is applied
  /// regardless of the generic tier (ADR-0015 Décision 4).
  double? get temperatureMaxTolerance => _temperatureMaxTolerance;

  /// Common name for [locale], falling back to French (always present).
  String nomLocalise(String locale) =>
      _nomsLocalises[locale] ?? _nomsLocalises['fr']!;

  /// Short description for [locale] (falls back to French), or `null` if the
  /// sheet carries none.
  String? descriptionLocalisee(String locale) =>
      _descriptionsLocalisees[locale] ?? _descriptionsLocalisees['fr'];

  /// Cultivation windows for a (hemisphere, climate) pair, or `null` if unknown.
  PeriodesCulture? periodesPour(Hemisphere hemisphere, TypeClimat climat) =>
      _periodes[hemisphere]?[climat];

  /// Whether the plant can be put in the ground on [date] in the given
  /// [hemisphere] and [climat]. False when no period data is available.
  bool estPlantableEn(DateTime date, Hemisphere hemisphere, TypeClimat climat) =>
      periodesPour(hemisphere, climat)?.plantableEnMois(date.month) ?? false;

  /// Whether the plant is compatible with [typeParcelle].
  ///
  /// Container types ([TypeParcelle.pot], [TypeParcelle.jardiniere]) are
  /// rejected when [compatibleHorsSol] is `false`. All other parcelle types
  /// are always accepted.
  bool estCompatibleAvec(TypeParcelle typeParcelle) {
    const contenants = {TypeParcelle.pot, TypeParcelle.jardiniere};
    return compatibleHorsSol || !contenants.contains(typeParcelle);
  }

  /// Whether this plant benefits from being grown near [planteId].
  bool sAssocieBienAvec(String planteId) =>
      _associationsBenefiques.any((a) => a.cibleId == planteId);

  /// Whether this plant conflicts with [planteId].
  bool entreEnConflitAvec(String planteId) =>
      _associationsNegatives.any((a) => a.cibleId == planteId);

  /// The beneficial association this plant declares towards [planteId], or
  /// `null` when none is declared (ADR-0010). Lets callers read the mechanism
  /// and reason behind a "good companion" relation.
  AssociationBenefique? associationBenefiqueAvec(String planteId) {
    for (final a in _associationsBenefiques) {
      if (a.cibleId == planteId) return a;
    }
    return null;
  }

  /// The conflicting association this plant declares towards [planteId], or
  /// `null` when none is declared (ADR-0010).
  AssociationConflit? associationConflitAvec(String planteId) {
    for (final a in _associationsNegatives) {
      if (a.cibleId == planteId) return a;
    }
    return null;
  }

  /// Whether the plant has the given functional [usage].
  bool aUsage(UsagePlante usage) => _usages.contains(usage);

  /// Whether the plant repels the bioaggressor [slug] (ADR-0010 Lot 2).
  bool repousse(String slug) => _repulsifContre.contains(slug);

  /// Whether the plant traps the bioaggressor [slug] as a decoy (ADR-0010 Lot 2).
  bool piege(String slug) => _piegeA.contains(slug);

  @override
  bool operator ==(Object other) => other is FichePlante && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'FichePlante($_id, ${_categorie.name})';
}
