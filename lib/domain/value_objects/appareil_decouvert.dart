/// Immutable description of a device discovered on the local network for sync
/// (DTO carried by `AbstractSyncService`).
///
/// See `docs/05-modele-de-domaine.md` §7.
class AppareilDecouvert {
  final String _id;
  final String _nom;
  final String _adresseIp;
  final int _port;
  final DateTime _derniereVue;

  const AppareilDecouvert._(
    this._id,
    this._nom,
    this._adresseIp,
    this._port,
    this._derniereVue,
  )   : assert(_id != '', 'id must not be empty'),
        assert(_nom != '', 'nom must not be empty'),
        assert(_port > 0, 'port must be > 0');

  const AppareilDecouvert({
    required String id,
    required String nom,
    required String adresseIp,
    required int port,
    required DateTime derniereVue,
  }) : this._(id, nom, adresseIp, port, derniereVue);

  String get id => _id;
  String get nom => _nom;
  String get adresseIp => _adresseIp;
  int get port => _port;
  DateTime get derniereVue => _derniereVue;

  @override
  bool operator ==(Object other) =>
      other is AppareilDecouvert &&
      other._id == _id &&
      other._nom == _nom &&
      other._adresseIp == _adresseIp &&
      other._port == _port &&
      other._derniereVue == _derniereVue;

  @override
  int get hashCode => Object.hash(_id, _nom, _adresseIp, _port, _derniereVue);
}
