import '../../domain/entities/tache.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../domain/services/acces_niveau.dart';
import 'geste_groupe.dart';

/// One garden zone, reduced to what the Accueil overview tiles display.
///
/// A lightweight projection of `Parcelle` — the dashboard only needs the name
/// (and an id to navigate later), not the full entity graph.
class ZoneApercu {
  final String _id;
  final String _nom;

  const ZoneApercu._(this._id, this._nom);

  /// Creates a zone overview projection.
  factory ZoneApercu({required String id, required String nom}) =>
      ZoneApercu._(id, nom);

  /// Zone (parcelle) identifier.
  String get id => _id;

  /// Display name of the zone.
  String get nom => _nom;
}

/// Immutable view-model assembled for the **Accueil** dashboard.
///
/// Built by [AccueilNotifier] from the repositories, it carries only what the
/// screen renders and resolves the progressive-disclosure rule once
/// ([statistiquesVisibles]) so the widget stays declarative.
///
/// Progressive disclosure (docs/02, écran Accueil) keyed on the real domain
/// [NiveauExperience] (3 levels). The mock-up's 4 labels collapse onto these:
///  - [NiveauExperience.debutant] / [NiveauExperience.intermediaire] → core only
///    (weather · tasks · alert · garden overview);
///  - [NiveauExperience.expert] → also the season statistics (harvests).
class AccueilVue {
  final String? _nomPotager;
  final NiveauExperience _niveau;
  final List<ZoneApercu> _zones;
  final List<Tache> _tachesDuJour;
  final List<GesteGroupe> _gestesDuJour;
  final int _nombreAlertes;
  final int _nombreRecoltesSaison;

  AccueilVue._(
    this._nomPotager,
    this._niveau,
    List<ZoneApercu> zones,
    List<Tache> tachesDuJour,
    this._nombreAlertes,
    this._nombreRecoltesSaison,
  )   : _zones = List.unmodifiable(zones),
        _tachesDuJour = List.unmodifiable(tachesDuJour),
        _gestesDuJour = List.unmodifiable(GesteGroupe.grouper(tachesDuJour));

  /// Assembles the dashboard view-model. Lists are copied as unmodifiable.
  factory AccueilVue({
    required String? nomPotager,
    required NiveauExperience niveau,
    required List<ZoneApercu> zones,
    required List<Tache> tachesDuJour,
    int nombreAlertes = 0,
    int nombreRecoltesSaison = 0,
  }) =>
      AccueilVue._(nomPotager, niveau, zones, tachesDuJour, nombreAlertes,
          nombreRecoltesSaison);

  /// Name of the active garden, or `null` when none exists yet (empty state).
  String? get nomPotager => _nomPotager;

  /// User experience level — drives progressive disclosure.
  NiveauExperience get niveau => _niveau;

  /// Zones of the active garden (immutable).
  List<ZoneApercu> get zones => _zones;

  /// Today's tasks across the whole garden (immutable), most relevant first.
  List<Tache> get tachesDuJour => _tachesDuJour;

  /// Today's tasks folded into one entry per gesture type (immutable) — what
  /// the dashboard list renders, so it matches the Calendrier agenda.
  List<GesteGroupe> get gestesDuJour => _gestesDuJour;

  /// Number of zones in the active garden.
  int get nombreZones => _zones.length;

  /// Number of today's tasks still to do (not completed/cancelled).
  int get nombreTachesAFaire => _tachesDuJour.where((t) => !t.estFaite).length;

  /// Number of active weather alerts for the garden (0 when no position/data).
  int get nombreAlertes => _nombreAlertes;

  /// Number of harvests recorded this season (current year).
  int get nombreRecoltesSaison => _nombreRecoltesSaison;

  /// Whether the season-statistics tile is unlocked for this level (routed
  /// through the single-source-of-truth policy — ADR-0009).
  bool get statistiquesVisibles => AccesNiveau(_niveau).statsTableauBord;

  /// Whether the active garden has no zones yet (drives the empty state).
  bool get potagerVide => _nomPotager == null || _zones.isEmpty;
}
