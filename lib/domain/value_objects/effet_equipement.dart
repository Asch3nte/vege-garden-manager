import '../enums/type_equipement.dart';

/// Immutable value object describing the agronomic effect of a piece of
/// equipment: how it modifies water need, sunlight and temperature, which
/// protections it provides, and whether it offers physical support or favours
/// biodiversity.
///
/// The numeric modifiers exposed here are **provisional**: their precise values
/// will be calibrated at the recommendation-engine step. The *shape* of the VO
/// is what matters for now. See `docs/05-modele-de-domaine.md` §4.7.
///
/// Domain names are kept in French; the code is documented in English.
class EffetEquipement {
  /// Multiplier applied to a plant's water need (1.0 = neutral, `< 1` reduces).
  final double _modificateurBesoinEau;

  /// Multiplier applied to received sunlight (1.0 = neutral, `< 1` shades).
  final double _modificateurEnsoleillement;

  /// Temperature delta in °C added by the equipment (0 = neutral, `> 0` warms).
  final double _modificateurTemperatureC;

  final bool _protectionGel;
  final bool _protectionInsectes;
  final bool _protectionOiseaux;
  final bool _supportPhysique;
  final bool _favoriseBiodiversite;

  /// How long the effect lasts, in days, or `null` when permanent / unbounded.
  final int? _dureeEfficaciteJours;

  const EffetEquipement._(
    this._modificateurBesoinEau,
    this._modificateurEnsoleillement,
    this._modificateurTemperatureC,
    this._protectionGel,
    this._protectionInsectes,
    this._protectionOiseaux,
    this._supportPhysique,
    this._favoriseBiodiversite,
    this._dureeEfficaciteJours,
  )   : assert(_modificateurBesoinEau > 0, 'water modifier must be > 0'),
        assert(_modificateurEnsoleillement > 0, 'sunlight modifier must be > 0'),
        assert(
          _dureeEfficaciteJours == null || _dureeEfficaciteJours > 0,
          'duration, when set, must be > 0',
        );

  /// Builds an effect from explicit modifiers; every parameter is neutral by
  /// default, so callers only set what the equipment actually changes.
  factory EffetEquipement({
    double modificateurBesoinEau = 1.0,
    double modificateurEnsoleillement = 1.0,
    double modificateurTemperatureC = 0.0,
    bool protectionGel = false,
    bool protectionInsectes = false,
    bool protectionOiseaux = false,
    bool supportPhysique = false,
    bool favoriseBiodiversite = false,
    int? dureeEfficaciteJours,
  }) =>
      EffetEquipement._(
        modificateurBesoinEau,
        modificateurEnsoleillement,
        modificateurTemperatureC,
        protectionGel,
        protectionInsectes,
        protectionOiseaux,
        supportPhysique,
        favoriseBiodiversite,
        dureeEfficaciteJours,
      );

  /// A neutral effect (no modification, no protection).
  static const EffetEquipement neutre =
      EffetEquipement._(1, 1, 0, false, false, false, false, false, null);

  /// Provisional effect associated with an equipment [type]. Numeric values are
  /// placeholders to be calibrated at the engine step.
  factory EffetEquipement.pourType(TypeEquipement type) => switch (type) {
        TypeEquipement.oya =>
          EffetEquipement(modificateurBesoinEau: 0.4),
        TypeEquipement.gouttesAGoutte =>
          EffetEquipement(modificateurBesoinEau: 0.7),
        TypeEquipement.tuteur => EffetEquipement(supportPhysique: true),
        TypeEquipement.treillis => EffetEquipement(supportPhysique: true),
        TypeEquipement.tunnel => EffetEquipement(
            modificateurTemperatureC: 4,
            protectionGel: true,
          ),
        TypeEquipement.serreSemis =>
          EffetEquipement(modificateurTemperatureC: 5, protectionGel: true),
        TypeEquipement.chassis =>
          EffetEquipement(modificateurTemperatureC: 3, protectionGel: true),
        TypeEquipement.cloche =>
          EffetEquipement(modificateurTemperatureC: 2, protectionGel: true),
        TypeEquipement.voileHivernage =>
          EffetEquipement(modificateurTemperatureC: 3, protectionGel: true),
        TypeEquipement.filetAntiInsecte =>
          EffetEquipement(protectionInsectes: true),
        TypeEquipement.hotelInsectes =>
          EffetEquipement(favoriseBiodiversite: true),
        TypeEquipement.composteur =>
          EffetEquipement(favoriseBiodiversite: true),
        TypeEquipement.recuperateurEau => EffetEquipement.neutre,
        TypeEquipement.autre => EffetEquipement.neutre,
      };

  double get modificateurBesoinEau => _modificateurBesoinEau;
  double get modificateurEnsoleillement => _modificateurEnsoleillement;
  double get modificateurTemperatureC => _modificateurTemperatureC;
  bool get protectionGel => _protectionGel;
  bool get protectionInsectes => _protectionInsectes;
  bool get protectionOiseaux => _protectionOiseaux;
  bool get supportPhysique => _supportPhysique;
  bool get favoriseBiodiversite => _favoriseBiodiversite;

  /// Effect duration in days, or `null` when permanent / unbounded.
  int? get dureeEfficaciteJours => _dureeEfficaciteJours;

  @override
  bool operator ==(Object other) =>
      other is EffetEquipement &&
      other._modificateurBesoinEau == _modificateurBesoinEau &&
      other._modificateurEnsoleillement == _modificateurEnsoleillement &&
      other._modificateurTemperatureC == _modificateurTemperatureC &&
      other._protectionGel == _protectionGel &&
      other._protectionInsectes == _protectionInsectes &&
      other._protectionOiseaux == _protectionOiseaux &&
      other._supportPhysique == _supportPhysique &&
      other._favoriseBiodiversite == _favoriseBiodiversite &&
      other._dureeEfficaciteJours == _dureeEfficaciteJours;

  @override
  int get hashCode => Object.hash(
        _modificateurBesoinEau,
        _modificateurEnsoleillement,
        _modificateurTemperatureC,
        _protectionGel,
        _protectionInsectes,
        _protectionOiseaux,
        _supportPhysique,
        _favoriseBiodiversite,
        _dureeEfficaciteJours,
      );
}
