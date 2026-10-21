/// Notification texts in the user language.
abstract class AbstractTextesNotifications {
  /// Language code of the texts, also used for the crop names they quote.
  String get langue;

  /// Title of the daily watering recap naming [noms] among [total] crops.
  String titreRecapArrosage(List<String> noms, int total);

  /// Body of the daily watering recap naming [noms] among [total] crops.
  String corpsRecapArrosage(List<String> noms, int total);
}
