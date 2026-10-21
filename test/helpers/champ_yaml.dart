/// Value at [cle] of the mapping found at [section] of [m].
Object? champ(Map<dynamic, dynamic> m, String section, String cle) =>
    (m[section] as Map<dynamic, dynamic>)[cle];
