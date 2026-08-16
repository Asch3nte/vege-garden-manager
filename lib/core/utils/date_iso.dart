/// Symmetric ISO-8601 conversion for dates persisted in SQLite.
///
/// Dates are stored as **UTC** ISO-8601 strings (fixed width, so lexicographic
/// order matches chronological order — range queries rely on it). The domain,
/// on the other hand, reasons in **local** time: `DateTime.now()`,
/// `DateTime(y, m, d)` and every day-level comparison (`.day`, "same day",
/// grouping by day) are local.
///
/// Reading a stored value with a bare `DateTime.parse` yields a *UTC* instant,
/// which is the same point in time but a different calendar day for any
/// non-zero timezone offset. Comparing it to a local day then silently fails
/// (e.g. local `2026-06-10 00:00` round-trips to `2026-06-09 22:00Z` in
/// UTC+2). [depuisStockage] closes that asymmetry: what goes in comes back out.
///
/// Both directions are pure and total; the pair is an exact round-trip.
abstract final class DateIso {
  /// Serialises [date] for storage (UTC ISO-8601).
  static String versStockage(DateTime date) => date.toUtc().toIso8601String();

  /// Serialises [date] for storage, or `null` when [date] is `null`.
  static String? versStockageNullable(DateTime? date) =>
      date == null ? null : versStockage(date);

  /// Parses a stored ISO-8601 string back into a **local** [DateTime].
  static DateTime depuisStockage(String iso) => DateTime.parse(iso).toLocal();

  /// Parses a stored ISO-8601 string, or `null` when [iso] is `null`.
  static DateTime? depuisStockageNullable(String? iso) =>
      iso == null ? null : depuisStockage(iso);

  /// The current instant serialised for storage.
  static String maintenant() => versStockage(DateTime.now());
}
