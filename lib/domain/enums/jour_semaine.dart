/// Day of the week, Monday-first (matches `DateTime.weekday` 1..7).
///
/// See `docs/05-modele-de-domaine.md` §5.
enum JourSemaine { lundi, mardi, mercredi, jeudi, vendredi, samedi, dimanche }

/// Maps a [DateTime] to its [JourSemaine].
extension JourSemaineDate on DateTime {
  JourSemaine get jourSemaine => JourSemaine.values[weekday - 1];
}
