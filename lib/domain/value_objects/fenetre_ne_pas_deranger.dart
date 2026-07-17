/// Immutable value object for a **do-not-disturb** window: a daily time range
/// during which the app must not fire notifications (docs/11 opt-outs).
///
/// Bounds are minutes since midnight (0–1439). The range is **half-open**
/// `[debut, fin)` — a notification exactly at [debutMinutes] is inside the
/// window (suppressed), one exactly at [finMinutes] is outside (allowed). Like
/// [Periode] for months, the window **may wrap across midnight**: 22:00 → 07:00
/// (`debut > fin`) covers the evening and the early morning.
///
/// A degenerate window where both bounds are equal covers nothing.
///
/// Domain field names are kept in French (spec); code/doc are in English.
class FenetreNePasDeranger {
  /// Start of the window, minutes since midnight (0–1439), inclusive.
  final int _debutMinutes;

  /// End of the window, minutes since midnight (0–1439), exclusive.
  final int _finMinutes;

  /// Creates a window from minute-of-day bounds (both 0–1439).
  const FenetreNePasDeranger(this._debutMinutes, this._finMinutes)
      : assert(
          _debutMinutes >= 0 && _debutMinutes <= 1439,
          'debutMinutes must be in 0..1439',
        ),
        assert(
          _finMinutes >= 0 && _finMinutes <= 1439,
          'finMinutes must be in 0..1439',
        );

  /// Parses a window from two `HH:MM` strings, or returns `null` when either is
  /// missing or malformed (lenient, so a corrupt stored value can never crash a
  /// read — the caller treats `null` as "no window").
  static FenetreNePasDeranger? depuisHeures(String? debut, String? fin) {
    final d = _minutesDepuisHeure(debut);
    final f = _minutesDepuisHeure(fin);
    if (d == null || f == null) return null;
    return FenetreNePasDeranger(d, f);
  }

  /// Minutes since midnight for a `HH:MM` string, or `null` if malformed.
  static int? _minutesDepuisHeure(String? heure) {
    if (heure == null) return null;
    final parts = heure.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  /// Start of the window, minutes since midnight (0–1439).
  int get debutMinutes => _debutMinutes;

  /// End of the window, minutes since midnight (0–1439).
  int get finMinutes => _finMinutes;

  /// Whether the window wraps across midnight (e.g. 22:00 → 07:00).
  bool get chevaucheMinuit => _debutMinutes > _finMinutes;

  /// Whether [date]'s time-of-day falls within the window (half-open
  /// `[debut, fin)`, wrapping across midnight when needed). Equal bounds cover
  /// nothing.
  bool contient(DateTime date) {
    if (_debutMinutes == _finMinutes) return false;
    final t = date.hour * 60 + date.minute;
    return chevaucheMinuit
        ? t >= _debutMinutes || t < _finMinutes
        : t >= _debutMinutes && t < _finMinutes;
  }

  @override
  bool operator ==(Object other) =>
      other is FenetreNePasDeranger &&
      other._debutMinutes == _debutMinutes &&
      other._finMinutes == _finMinutes;

  @override
  int get hashCode => Object.hash(_debutMinutes, _finMinutes);

  @override
  String toString() =>
      'FenetreNePasDeranger($_debutMinutes→$_finMinutes)';
}
