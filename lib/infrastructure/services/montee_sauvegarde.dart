import '../database/teintes_zone_v8.dart';

/// Brings the tables of a backup from an older schema version to the current
/// one, mirroring the database migrations.
///
/// Columns added since are left out of the rows and take their default; only
/// data reshaped by a migration is rewritten here.
class MonteeSauvegarde {
  /// Schema version the backups are brought to; follows the database's.
  static const int versionCible = 9;

  const MonteeSauvegarde();

  /// Rewrites [tables] in place from schema version [depuis].
  void monter(Map<String, dynamic> tables, int depuis) {
    if (depuis < 7) _versV7(tables);
    if (depuis < 8) _versV8(tables);
  }

  /// The engine's French watering titles become derived ones, matched like
  /// the database migration (`LIKE` ignores ASCII case).
  void _versV7(Map<String, dynamic> tables) {
    final taches = tables['taches'];
    if (taches is! List) return;
    for (final ligne in taches.whereType<Map<String, dynamic>>()) {
      final titre = ligne['titre'];
      if (ligne['type'] == 'arrosage' &&
          ligne['plantation_id'] != null &&
          titre is String &&
          (titre == 'Arroser' ||
              titre.toLowerCase().startsWith('arroser : '))) {
        ligne['titre'] = null;
        ligne['generee'] = 1;
      }
    }
  }

  /// Each zone keeps the tint it showed by its position among its garden's
  /// live zones, as the database migration does.
  void _versV8(Map<String, dynamic> tables) {
    final parcelles = tables['parcelles'];
    if (parcelles is! List) return;
    final vivantes = parcelles
        .whereType<Map<String, dynamic>>()
        .where((l) => l['deleted_at'] == null)
        .toList();
    // Same order as the zone list: position, creation, then file order.
    final triees = [
      for (final (i, l) in vivantes.indexed) (i, l),
    ]..sort((a, b) {
        final ordre = _position(a.$2).compareTo(_position(b.$2));
        if (ordre != 0) return ordre;
        final creation = '${a.$2['created_at'] ?? ''}'
            .compareTo('${b.$2['created_at'] ?? ''}');
        return creation != 0 ? creation : a.$1.compareTo(b.$1);
      });
    final rangs = <Object?, int>{};
    for (final (_, ligne) in triees) {
      final rang = rangs.update(ligne['potager_id'], (r) => r + 1,
          ifAbsent: () => 0);
      ligne['couleur_teinte'] = teintesZoneV8[rang % teintesZoneV8.length];
    }
  }

  /// Malformed positions sort first; the row import rejects them afterwards.
  static num _position(Map<String, dynamic> ligne) {
    final position = ligne['position_ordre'];
    return position is num ? position : 0;
  }
}
