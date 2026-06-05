/// User's global geolocation mode preference (distinct from a potager's data
/// origin `SourceLocalisation`). `desactivee` is the privacy default.
///
/// See `docs/06-modele-de-donnees-sqlite.md` §3.12.
enum ModeGeolocalisation { desactivee, manuelle, gps }
