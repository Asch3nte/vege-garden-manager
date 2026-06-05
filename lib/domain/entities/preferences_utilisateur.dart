import '../enums/langue.dart';
import '../enums/mode_geolocalisation.dart';
import '../enums/niveau_experience.dart';
import '../enums/sens_swipe.dart';
import '../enums/systeme_unites.dart';
import '../enums/theme_app.dart';

/// User settings (language, theme, units, opt-outs, notifications…).
///
/// A singleton (`id == 'singleton'`) and **immutable**: every change produces a
/// new instance via [copierAvec] (or the dedicated do-not-disturb helpers).
/// Because it is a singleton configuration, equality is **by value** (unlike the
/// other entities, which use identity).
///
/// Domain names are kept in French; the code is documented in English.
/// See `docs/05-modele-de-domaine.md` §3.7 and `docs/06` §3.12.
class PreferencesUtilisateur {
  /// The fixed identity of the single preferences row.
  static const String idSingleton = 'singleton';

  final Langue _langue;
  final ThemeApp _theme;
  final SystemeUnites _systemeUnites;
  final SensSwipe _sensSwipe;
  final NiveauExperience _niveauExperience;
  final ModeGeolocalisation _modeGeolocalisation;
  final bool _notificationsGlobalesActives;
  final bool _syncLocaleActive;
  final bool _communauteOptIn;
  final bool _calendrierLunaireOptIn;
  final bool _aideContextuelleActive;
  final bool _aideDocCompleteActive;
  final Map<String, bool> _notificationsParCategorie;
  final String? _nePasDerangerDebut;
  final String? _nePasDerangerFin;

  PreferencesUtilisateur._(
    this._langue,
    this._theme,
    this._systemeUnites,
    this._sensSwipe,
    this._niveauExperience,
    this._modeGeolocalisation,
    this._notificationsGlobalesActives,
    this._syncLocaleActive,
    this._communauteOptIn,
    this._calendrierLunaireOptIn,
    this._aideContextuelleActive,
    this._aideDocCompleteActive,
    this._notificationsParCategorie,
    this._nePasDerangerDebut,
    this._nePasDerangerFin,
  ) : assert(
          (_nePasDerangerDebut == null) == (_nePasDerangerFin == null),
          'do-not-disturb bounds must be both set or both null',
        );

  /// Creates a preferences object. All defaults are the "smart defaults" of the
  /// spec (privacy-first: geolocation off, sync off, beginner level).
  factory PreferencesUtilisateur({
    Langue langue = Langue.auto,
    ThemeApp theme = ThemeApp.auto,
    SystemeUnites systemeUnites = SystemeUnites.metrique,
    SensSwipe sensSwipe = SensSwipe.standard,
    NiveauExperience niveauExperience = NiveauExperience.debutant,
    ModeGeolocalisation modeGeolocalisation = ModeGeolocalisation.desactivee,
    bool notificationsGlobalesActives = true,
    bool syncLocaleActive = false,
    bool communauteOptIn = false,
    bool calendrierLunaireOptIn = false,
    bool aideContextuelleActive = true,
    bool aideDocCompleteActive = true,
    Map<String, bool> notificationsParCategorie = const {},
    String? nePasDerangerDebut,
    String? nePasDerangerFin,
  }) =>
      PreferencesUtilisateur._(
        langue,
        theme,
        systemeUnites,
        sensSwipe,
        niveauExperience,
        modeGeolocalisation,
        notificationsGlobalesActives,
        syncLocaleActive,
        communauteOptIn,
        calendrierLunaireOptIn,
        aideContextuelleActive,
        aideDocCompleteActive,
        Map.unmodifiable(notificationsParCategorie),
        nePasDerangerDebut,
        nePasDerangerFin,
      );

  String get id => idSingleton;
  Langue get langue => _langue;
  ThemeApp get theme => _theme;
  SystemeUnites get systemeUnites => _systemeUnites;
  SensSwipe get sensSwipe => _sensSwipe;
  NiveauExperience get niveauExperience => _niveauExperience;
  ModeGeolocalisation get modeGeolocalisation => _modeGeolocalisation;
  bool get notificationsGlobalesActives => _notificationsGlobalesActives;
  bool get syncLocaleActive => _syncLocaleActive;
  bool get communauteOptIn => _communauteOptIn;
  bool get calendrierLunaireOptIn => _calendrierLunaireOptIn;
  bool get aideContextuelleActive => _aideContextuelleActive;
  bool get aideDocCompleteActive => _aideDocCompleteActive;
  Map<String, bool> get notificationsParCategorie =>
      Map.unmodifiable(_notificationsParCategorie);

  /// Start of the do-not-disturb window (`HH:MM`), or `null` when disabled.
  String? get nePasDerangerDebut => _nePasDerangerDebut;

  /// End of the do-not-disturb window (`HH:MM`), or `null` when disabled.
  String? get nePasDerangerFin => _nePasDerangerFin;

  /// Whether a do-not-disturb window is configured.
  bool get nePasDerangerActif => _nePasDerangerDebut != null;

  /// Returns a copy with the given fields overridden (do-not-disturb is kept;
  /// use [avecNePasDeranger] / [sansNePasDeranger] to change it).
  PreferencesUtilisateur copierAvec({
    Langue? langue,
    ThemeApp? theme,
    SystemeUnites? systemeUnites,
    SensSwipe? sensSwipe,
    NiveauExperience? niveauExperience,
    ModeGeolocalisation? modeGeolocalisation,
    bool? notificationsGlobalesActives,
    bool? syncLocaleActive,
    bool? communauteOptIn,
    bool? calendrierLunaireOptIn,
    bool? aideContextuelleActive,
    bool? aideDocCompleteActive,
    Map<String, bool>? notificationsParCategorie,
  }) =>
      PreferencesUtilisateur(
        langue: langue ?? _langue,
        theme: theme ?? _theme,
        systemeUnites: systemeUnites ?? _systemeUnites,
        sensSwipe: sensSwipe ?? _sensSwipe,
        niveauExperience: niveauExperience ?? _niveauExperience,
        modeGeolocalisation: modeGeolocalisation ?? _modeGeolocalisation,
        notificationsGlobalesActives:
            notificationsGlobalesActives ?? _notificationsGlobalesActives,
        syncLocaleActive: syncLocaleActive ?? _syncLocaleActive,
        communauteOptIn: communauteOptIn ?? _communauteOptIn,
        calendrierLunaireOptIn:
            calendrierLunaireOptIn ?? _calendrierLunaireOptIn,
        aideContextuelleActive:
            aideContextuelleActive ?? _aideContextuelleActive,
        aideDocCompleteActive:
            aideDocCompleteActive ?? _aideDocCompleteActive,
        notificationsParCategorie:
            notificationsParCategorie ?? _notificationsParCategorie,
        nePasDerangerDebut: _nePasDerangerDebut,
        nePasDerangerFin: _nePasDerangerFin,
      );

  /// Returns a copy with a do-not-disturb window (`HH:MM` bounds).
  PreferencesUtilisateur avecNePasDeranger(String debut, String fin) =>
      copierAvec()._avecNpd(debut, fin);

  /// Returns a copy with the do-not-disturb window cleared.
  PreferencesUtilisateur sansNePasDeranger() => copierAvec()._avecNpd(null, null);

  PreferencesUtilisateur _avecNpd(String? debut, String? fin) =>
      PreferencesUtilisateur(
        langue: _langue,
        theme: _theme,
        systemeUnites: _systemeUnites,
        sensSwipe: _sensSwipe,
        niveauExperience: _niveauExperience,
        modeGeolocalisation: _modeGeolocalisation,
        notificationsGlobalesActives: _notificationsGlobalesActives,
        syncLocaleActive: _syncLocaleActive,
        communauteOptIn: _communauteOptIn,
        calendrierLunaireOptIn: _calendrierLunaireOptIn,
        aideContextuelleActive: _aideContextuelleActive,
        aideDocCompleteActive: _aideDocCompleteActive,
        notificationsParCategorie: _notificationsParCategorie,
        nePasDerangerDebut: debut,
        nePasDerangerFin: fin,
      );

  @override
  bool operator ==(Object other) =>
      other is PreferencesUtilisateur &&
      other._langue == _langue &&
      other._theme == _theme &&
      other._systemeUnites == _systemeUnites &&
      other._sensSwipe == _sensSwipe &&
      other._niveauExperience == _niveauExperience &&
      other._modeGeolocalisation == _modeGeolocalisation &&
      other._notificationsGlobalesActives == _notificationsGlobalesActives &&
      other._syncLocaleActive == _syncLocaleActive &&
      other._communauteOptIn == _communauteOptIn &&
      other._calendrierLunaireOptIn == _calendrierLunaireOptIn &&
      other._aideContextuelleActive == _aideContextuelleActive &&
      other._aideDocCompleteActive == _aideDocCompleteActive &&
      other._nePasDerangerDebut == _nePasDerangerDebut &&
      other._nePasDerangerFin == _nePasDerangerFin &&
      _memeMap(other._notificationsParCategorie, _notificationsParCategorie);

  @override
  int get hashCode => Object.hash(
        _langue,
        _theme,
        _systemeUnites,
        _sensSwipe,
        _niveauExperience,
        _modeGeolocalisation,
        Object.hash(
          _notificationsGlobalesActives,
          _syncLocaleActive,
          _communauteOptIn,
          _calendrierLunaireOptIn,
          _aideContextuelleActive,
          _aideDocCompleteActive,
          _nePasDerangerDebut,
          _nePasDerangerFin,
        ),
        _notificationsParCategorie.entries
            .fold<int>(0, (h, e) => h ^ Object.hash(e.key, e.value)),
      );

  static bool _memeMap(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
