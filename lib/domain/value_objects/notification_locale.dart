/// Immutable description of a local notification to schedule (DTO carried by
/// `AbstractNotificationService`).
///
/// Named `NotificationLocale` to avoid clashing with the Flutter/OS
/// `Notification` class. See `docs/05-modele-de-domaine.md` §7.
class NotificationLocale {
  final String _id;
  final String _titre;
  final String _corps;
  final DateTime _dateProgrammee;
  final String _categorie;
  final String? _cibleRoute;

  const NotificationLocale._(
    this._id,
    this._titre,
    this._corps,
    this._dateProgrammee,
    this._categorie,
    this._cibleRoute,
  )   : assert(_id != '', 'id must not be empty'),
        assert(_titre != '', 'titre must not be empty'),
        assert(_categorie != '', 'categorie must not be empty');

  const NotificationLocale({
    required String id,
    required String titre,
    required String corps,
    required DateTime dateProgrammee,
    required String categorie,
    String? cibleRoute,
  }) : this._(id, titre, corps, dateProgrammee, categorie, cibleRoute);

  String get id => _id;
  String get titre => _titre;
  String get corps => _corps;
  DateTime get dateProgrammee => _dateProgrammee;

  /// Category key used for per-category opt-outs (e.g. `arrosage`, `semis`).
  String get categorie => _categorie;

  /// Optional in-app route to open when the notification is tapped.
  String? get cibleRoute => _cibleRoute;

  /// Returns a copy overriding the given fields (used to defer the schedule out
  /// of a do-not-disturb window — see `FiltreNotifications`).
  NotificationLocale copierAvec({DateTime? dateProgrammee}) => NotificationLocale(
        id: _id,
        titre: _titre,
        corps: _corps,
        dateProgrammee: dateProgrammee ?? _dateProgrammee,
        categorie: _categorie,
        cibleRoute: _cibleRoute,
      );

  @override
  bool operator ==(Object other) =>
      other is NotificationLocale &&
      other._id == _id &&
      other._titre == _titre &&
      other._corps == _corps &&
      other._dateProgrammee == _dateProgrammee &&
      other._categorie == _categorie &&
      other._cibleRoute == _cibleRoute;

  @override
  int get hashCode => Object.hash(
      _id, _titre, _corps, _dateProgrammee, _categorie, _cibleRoute);
}
