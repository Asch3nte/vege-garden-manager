import 'periode.dart';

/// Immutable set of cultivation windows for one (hemisphere, climate) pair: when
/// to sow indoors/outdoors, plant out, and harvest. Each window is optional.
///
/// See `docs/05-modele-de-domaine.md` §3.6.
class PeriodesCulture {
  final Periode? _semisInterieur;
  final Periode? _semisExterieur;
  final Periode? _plantation;
  final Periode? _recolte;

  const PeriodesCulture._(
    this._semisInterieur,
    this._semisExterieur,
    this._plantation,
    this._recolte,
  );

  const PeriodesCulture({
    Periode? semisInterieur,
    Periode? semisExterieur,
    Periode? plantation,
    Periode? recolte,
  }) : this._(semisInterieur, semisExterieur, plantation, recolte);

  Periode? get semisInterieur => _semisInterieur;
  Periode? get semisExterieur => _semisExterieur;
  Periode? get plantation => _plantation;
  Periode? get recolte => _recolte;

  /// Whether the plant can be put in the ground in [mois] (1–12): inside the
  /// plant-out window, or the direct-sowing window.
  bool plantableEnMois(int mois) =>
      (_plantation?.contientMois(mois) ?? false) ||
      (_semisExterieur?.contientMois(mois) ?? false);

  @override
  bool operator ==(Object other) =>
      other is PeriodesCulture &&
      other._semisInterieur == _semisInterieur &&
      other._semisExterieur == _semisExterieur &&
      other._plantation == _plantation &&
      other._recolte == _recolte;

  @override
  int get hashCode =>
      Object.hash(_semisInterieur, _semisExterieur, _plantation, _recolte);
}
