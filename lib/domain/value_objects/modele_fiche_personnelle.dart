import '../enums/besoin_eau.dart';
import '../enums/categorie_plante.dart';
import '../enums/niveau_soleil.dart';
import '../enums/qualite_sol.dart';
import '../enums/sous_type_legume.dart';
import '../enums/usage_plante.dart';

/// Editable content of a user-authored plant sheet (MVP scope: identity +
/// basic cultivation).
///
/// This is the structured draft the in-app form edits. It is deliberately a
/// **subset** of the full [FichePlante] model (`docs/07 §7`): only the fields
/// the recommendation/watering engines strictly need to treat a personal sheet
/// like a built-in one. Richer fields (periods, associations, rusticity…) are
/// intentionally deferred and simply left absent from the emitted YAML.
///
/// The source of truth on disk is the emitted YAML (`yaml_contenu`); this model
/// is the round-trip representation. Invariants mirror what
/// `FichePlanteValidator` enforces on the YAML, caught early for a friendlier
/// form experience. Domain names stay in French; code is documented in English.
class ModeleFichePersonnelle {
  final String _idFiche;
  final CategoriePlante _categorie;
  final SousTypeLegume? _sousType;
  final Set<UsagePlante> _usages;
  final String _nomScientifique;
  final String _familleBotanique;
  final String _nomCommunFr;
  final String? _nomCommunEn;
  final String? _descriptionFr;
  final NiveauSoleil _ensoleillement;
  final BesoinEau _arrosage;
  final Set<QualiteSol> _qualitesSol;
  final double _phMin;
  final double _phMax;
  final int _espacementCm;
  final int _dureeAvantRecolteJoursMin;
  final int _dureeAvantRecolteJoursMax;
  final int? _difficulte;

  ModeleFichePersonnelle._(
    this._idFiche,
    this._categorie,
    this._sousType,
    this._usages,
    this._nomScientifique,
    this._familleBotanique,
    this._nomCommunFr,
    this._nomCommunEn,
    this._descriptionFr,
    this._ensoleillement,
    this._arrosage,
    this._qualitesSol,
    this._phMin,
    this._phMax,
    this._espacementCm,
    this._dureeAvantRecolteJoursMin,
    this._dureeAvantRecolteJoursMax,
    this._difficulte,
  )   : assert(_idFiche.isNotEmpty, 'idFiche must not be empty'),
        assert(_nomScientifique.isNotEmpty, 'nomScientifique must not be empty'),
        assert(
            _familleBotanique.isNotEmpty, 'familleBotanique must not be empty'),
        assert(_nomCommunFr.isNotEmpty, 'nomCommunFr must not be empty'),
        assert(_usages.isNotEmpty, 'at least one usage is required'),
        assert(
            _qualitesSol.isNotEmpty, 'at least one soil quality is required'),
        assert(_sousType == null || _categorie == CategoriePlante.legume,
            'sousType is only valid for a legume'),
        assert(_phMin >= 0 && _phMax <= 14, 'pH must be within 0..14'),
        assert(_phMin <= _phMax, 'phMin must be <= phMax'),
        assert(_espacementCm > 0, 'espacementCm must be positive'),
        assert(_dureeAvantRecolteJoursMin > 0 &&
            _dureeAvantRecolteJoursMin <= _dureeAvantRecolteJoursMax),
        assert(_difficulte == null || (_difficulte >= 1 && _difficulte <= 3),
            'difficulte must be within 1..3');

  /// Builds an editable personal-sheet model. String sets are copied and made
  /// immutable; [nomCommunEn] and [descriptionFr] are optional.
  factory ModeleFichePersonnelle({
    required String idFiche,
    required CategoriePlante categorie,
    required Set<UsagePlante> usages,
    required String nomScientifique,
    required String familleBotanique,
    required String nomCommunFr,
    required NiveauSoleil ensoleillement,
    required BesoinEau arrosage,
    required Set<QualiteSol> qualitesSol,
    required double phMin,
    required double phMax,
    required int espacementCm,
    required int dureeAvantRecolteJoursMin,
    required int dureeAvantRecolteJoursMax,
    SousTypeLegume? sousType,
    String? nomCommunEn,
    String? descriptionFr,
    int? difficulte,
  }) =>
      ModeleFichePersonnelle._(
        idFiche,
        categorie,
        categorie == CategoriePlante.legume ? sousType : null,
        Set.unmodifiable(usages),
        nomScientifique,
        familleBotanique,
        nomCommunFr,
        nomCommunEn,
        descriptionFr,
        ensoleillement,
        arrosage,
        Set.unmodifiable(qualitesSol),
        phMin,
        phMax,
        espacementCm,
        dureeAvantRecolteJoursMin,
        dureeAvantRecolteJoursMax,
        difficulte,
      );

  /// Logical, catalogue-wide unique id of the sheet (distinct from the storage
  /// row UUID). A personal sheet with this id overrides a built-in one.
  String get idFiche => _idFiche;
  CategoriePlante get categorie => _categorie;
  SousTypeLegume? get sousType => _sousType;
  Set<UsagePlante> get usages => _usages;
  String get nomScientifique => _nomScientifique;
  String get familleBotanique => _familleBotanique;
  String get nomCommunFr => _nomCommunFr;
  String? get nomCommunEn => _nomCommunEn;
  String? get descriptionFr => _descriptionFr;
  NiveauSoleil get ensoleillement => _ensoleillement;
  BesoinEau get arrosage => _arrosage;
  Set<QualiteSol> get qualitesSol => _qualitesSol;
  double get phMin => _phMin;
  double get phMax => _phMax;
  int get espacementCm => _espacementCm;
  int get dureeAvantRecolteJoursMin => _dureeAvantRecolteJoursMin;
  int get dureeAvantRecolteJoursMax => _dureeAvantRecolteJoursMax;
  int? get difficulte => _difficulte;

  /// Returns a copy with the given fields replaced. Passing [sousType] on a
  /// non-legume categorie has no effect (dropped by the factory).
  ModeleFichePersonnelle copyWith({
    String? idFiche,
    CategoriePlante? categorie,
    SousTypeLegume? sousType,
    Set<UsagePlante>? usages,
    String? nomScientifique,
    String? familleBotanique,
    String? nomCommunFr,
    String? nomCommunEn,
    String? descriptionFr,
    NiveauSoleil? ensoleillement,
    BesoinEau? arrosage,
    Set<QualiteSol>? qualitesSol,
    double? phMin,
    double? phMax,
    int? espacementCm,
    int? dureeAvantRecolteJoursMin,
    int? dureeAvantRecolteJoursMax,
    int? difficulte,
  }) =>
      ModeleFichePersonnelle(
        idFiche: idFiche ?? _idFiche,
        categorie: categorie ?? _categorie,
        sousType: sousType ?? _sousType,
        usages: usages ?? _usages,
        nomScientifique: nomScientifique ?? _nomScientifique,
        familleBotanique: familleBotanique ?? _familleBotanique,
        nomCommunFr: nomCommunFr ?? _nomCommunFr,
        nomCommunEn: nomCommunEn ?? _nomCommunEn,
        descriptionFr: descriptionFr ?? _descriptionFr,
        ensoleillement: ensoleillement ?? _ensoleillement,
        arrosage: arrosage ?? _arrosage,
        qualitesSol: qualitesSol ?? _qualitesSol,
        phMin: phMin ?? _phMin,
        phMax: phMax ?? _phMax,
        espacementCm: espacementCm ?? _espacementCm,
        dureeAvantRecolteJoursMin:
            dureeAvantRecolteJoursMin ?? _dureeAvantRecolteJoursMin,
        dureeAvantRecolteJoursMax:
            dureeAvantRecolteJoursMax ?? _dureeAvantRecolteJoursMax,
        difficulte: difficulte ?? _difficulte,
      );
}
