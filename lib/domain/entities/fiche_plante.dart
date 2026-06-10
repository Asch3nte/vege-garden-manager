import '../enums/categorie_plante.dart';
import '../enums/hemisphere.dart';
import '../enums/sous_type_legume.dart';
import '../enums/type_climat.dart';
import '../enums/usage_plante.dart';
import '../value_objects/besoins_culture.dart';
import '../value_objects/periodes_culture.dart';

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
  final Set<String> _associationsBenefiques;
  final Set<String> _associationsNegatives;
  final String? _rotationFamille;
  final int? _delaiRetourAnnees;
  final Map<String, String> _descriptionsLocalisees;

  FichePlante._(
    this._id,
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
    this._descriptionsLocalisees,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_nomScientifique.isNotEmpty, 'nomScientifique must not be empty'),
        assert(_familleBotanique.isNotEmpty, 'familleBotanique must not be empty'),
        assert(_usages.isNotEmpty, 'a plant must have at least one usage'),
        assert(_nomsLocalises.containsKey('fr'), 'the French name is mandatory'),
        assert(_espacementCm > 0, 'espacementCm must be > 0'),
        assert(
          _dureeAvantRecolteJoursMin > 0 &&
              _dureeAvantRecolteJoursMin <= _dureeAvantRecolteJoursMax,
          'duration must be positive with min <= max',
        );

  /// Builds a plant sheet. Collections are stored unmodifiable; periods default
  /// to empty.
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
    SousTypeLegume? sousType,
    Map<Hemisphere, Map<TypeClimat, PeriodesCulture>>? periodes,
    Set<String>? associationsBenefiques,
    Set<String>? associationsNegatives,
    String? rotationFamille,
    int? delaiRetourAnnees,
    Map<String, String>? descriptionsLocalisees,
  }) =>
      FichePlante._(
        id,
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
        Set<String>.unmodifiable(associationsBenefiques ?? const <String>{}),
        Set<String>.unmodifiable(associationsNegatives ?? const <String>{}),
        rotationFamille,
        delaiRetourAnnees,
        Map<String, String>.unmodifiable(descriptionsLocalisees ?? const {}),
      );

  static Map<Hemisphere, Map<TypeClimat, PeriodesCulture>> _figerPeriodes(
    Map<Hemisphere, Map<TypeClimat, PeriodesCulture>> p,
  ) =>
      Map<Hemisphere, Map<TypeClimat, PeriodesCulture>>.unmodifiable({
        for (final e in p.entries)
          e.key: Map<TypeClimat, PeriodesCulture>.unmodifiable(e.value),
      });

  String get id => _id;
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

  /// Whether this plant benefits from being grown near [planteId].
  bool sAssocieBienAvec(String planteId) =>
      _associationsBenefiques.contains(planteId);

  /// Whether this plant conflicts with [planteId].
  bool entreEnConflitAvec(String planteId) =>
      _associationsNegatives.contains(planteId);

  /// Whether the plant has the given functional [usage].
  bool aUsage(UsagePlante usage) => _usages.contains(usage);

  @override
  bool operator ==(Object other) => other is FichePlante && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'FichePlante($_id, ${_categorie.name})';
}
