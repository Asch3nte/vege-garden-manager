import '../../domain/value_objects/periode.dart';

/// One cultivated plant projected for the **Saison** calendar: its sowing,
/// planting and harvest windows (months), already resolved for the active
/// garden's hemisphere × climate. A window is `null` when the sheet has no data
/// for that (hemisphere, climate) pair.
class LigneSaison {
  final String _nom;
  final Periode? _semis;
  final Periode? _plantation;
  final Periode? _recolte;

  const LigneSaison._(this._nom, this._semis, this._plantation, this._recolte);

  /// Creates a season line for a plant and its (optional) windows.
  factory LigneSaison({
    required String nom,
    Periode? semis,
    Periode? plantation,
    Periode? recolte,
  }) =>
      LigneSaison._(nom, semis, plantation, recolte);

  /// Localized plant name.
  String get nom => _nom;

  /// Sowing window (outdoor first, else indoor), or `null` if unknown.
  Periode? get semis => _semis;

  /// Plant-out window, or `null` if unknown.
  Periode? get plantation => _plantation;

  /// Harvest window, or `null` if unknown.
  Periode? get recolte => _recolte;

  /// Whether any window is known for this plant in the current context.
  bool get aDesDonnees => _semis != null || _plantation != null || _recolte != null;
}

/// Immutable view-model for the **Saison** calendar view.
///
/// When [contexteConnu] is false there is no active garden. When
/// [hemisphereSuppose] is true the garden has no position, so the northern
/// hemisphere was assumed (shown with a caption — never silently, see the
/// onboarding-location decision).
class SaisonVue {
  final bool _contexteConnu;
  final bool _hemisphereSuppose;
  final List<LigneSaison> _lignes;

  SaisonVue._(this._contexteConnu, this._hemisphereSuppose, List<LigneSaison> lignes)
      : _lignes = List.unmodifiable(lignes);

  /// A populated season view for the active garden's cultivated plants.
  factory SaisonVue({
    required bool hemisphereSuppose,
    required List<LigneSaison> lignes,
  }) =>
      SaisonVue._(true, hemisphereSuppose, lignes);

  /// The "no active garden" view.
  factory SaisonVue.sansContexte() => SaisonVue._(false, false, const []);

  /// Whether an active garden (hence a climate context) exists.
  bool get contexteConnu => _contexteConnu;

  /// Whether the northern hemisphere was assumed (no position set).
  bool get hemisphereSuppose => _hemisphereSuppose;

  /// One line per distinct cultivated plant, ordered by name (immutable).
  List<LigneSaison> get lignes => _lignes;

  /// Whether the garden has no cultivated plant to chart.
  bool get vide => _lignes.isEmpty;
}
