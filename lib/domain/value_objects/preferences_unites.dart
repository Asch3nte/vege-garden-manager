import '../enums/grandeur_mesure.dart';
import '../enums/systeme_unites.dart';

/// Measurement system chosen for each [GrandeurMesure].
class PreferencesUnites {
  final SystemeUnites _temperature;
  final SystemeUnites _longueur;
  final SystemeUnites _surface;
  final SystemeUnites _volume;
  final SystemeUnites _masse;

  const PreferencesUnites._(
    this._temperature,
    this._longueur,
    this._surface,
    this._volume,
    this._masse,
  );

  /// Metric for any quantity not given.
  const PreferencesUnites({
    SystemeUnites temperature = SystemeUnites.metrique,
    SystemeUnites longueur = SystemeUnites.metrique,
    SystemeUnites surface = SystemeUnites.metrique,
    SystemeUnites volume = SystemeUnites.metrique,
    SystemeUnites masse = SystemeUnites.metrique,
  }) : this._(temperature, longueur, surface, volume, masse);

  /// The same [systeme] for every quantity (a preset).
  const PreferencesUnites.uniforme(SystemeUnites systeme)
    : this._(systeme, systeme, systeme, systeme, systeme);

  /// The system chosen for [grandeur].
  SystemeUnites pour(GrandeurMesure grandeur) => switch (grandeur) {
    GrandeurMesure.temperature => _temperature,
    GrandeurMesure.longueur => _longueur,
    GrandeurMesure.surface => _surface,
    GrandeurMesure.volume => _volume,
    GrandeurMesure.masse => _masse,
  };

  /// A copy with [grandeur] set to [systeme].
  PreferencesUnites avec(GrandeurMesure grandeur, SystemeUnites systeme) {
    SystemeUnites choix(GrandeurMesure g) => g == grandeur ? systeme : pour(g);
    return PreferencesUnites(
      temperature: choix(GrandeurMesure.temperature),
      longueur: choix(GrandeurMesure.longueur),
      surface: choix(GrandeurMesure.surface),
      volume: choix(GrandeurMesure.volume),
      masse: choix(GrandeurMesure.masse),
    );
  }

  /// The system shared by every quantity, or `null` when they are mixed.
  SystemeUnites? get prereglage {
    final systemes = {for (final g in GrandeurMesure.values) pour(g)};
    return systemes.length == 1 ? systemes.single : null;
  }

  @override
  bool operator ==(Object other) =>
      other is PreferencesUnites &&
      GrandeurMesure.values.every((g) => other.pour(g) == pour(g));

  @override
  int get hashCode =>
      Object.hash(_temperature, _longueur, _surface, _volume, _masse);
}
