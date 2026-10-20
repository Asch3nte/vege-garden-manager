/// Calendar-day arithmetic that ignores the time of day and DST shifts.
extension DateCalendaire on DateTime {
  /// Number of calendar days from this date to [autre].
  int joursJusqua(DateTime autre) => DateTime.utc(
    autre.year,
    autre.month,
    autre.day,
  ).difference(DateTime.utc(year, month, day)).inDays;

  /// Midnight [jours] calendar days after this date, in the same UTC/local kind.
  DateTime plusJours(int jours) => isUtc
      ? DateTime.utc(year, month, day + jours)
      : DateTime(year, month, day + jours);
}
