/// Type of equipment that can be installed on a parcelle (or shared at the
/// potager level).
///
/// Each type
/// maps to a provisional [EffetEquipement] via `EffetEquipement.pourType`.
enum TypeEquipement {
  oya,
  gouttesAGoutte,
  tuteur,
  treillis,
  tunnel,
  serreSemis,
  chassis,
  cloche,
  voileHivernage,
  filetAntiInsecte,
  hotelInsectes,
  composteur,
  recuperateurEau,
  autre,
}
